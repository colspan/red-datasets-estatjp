# frozen_string_literal: true

require 'datasets'

require 'digest/md5'
require 'net/http'
require 'uri'
require 'json'

module Datasets
  Record = Struct.new(:id, :name, :values)
  BASE_URL = 'http://api.e-stat.go.jp/rest/2.1/app/json/getStatsData'

  # Estat module
  module Estat
    # configuration injection
    module Configuration
      attr_accessor :app_id

      def configure
        yield self
      end
    end

    extend Configuration

    class EstatAPI < Dataset
      # a ruby wrapper for e-Stat API service
      attr_accessor :app_id, :areas, :timetables, :schema

      def self.generate_url(app_id,
                            stats_data_id,
                            area: nil, cat: nil, time: nil)
        # generates url for query
        params = {
          appId: app_id, lang: 'J',
          statsDataId: stats_data_id, # 表番号
          metaGetFlg: 'Y', cntGetFlg: 'N',
          sectionHeaderFlg: '1'
        }
        # cdArea: ["01105", "01106"].join(","), # 地域
        params['cdArea'] = area.join(',') if area.instance_of?(Array)
        # cdCat01: ["A2101", "A210101", "A210102", "A2201", "A2301", "A4101", "A4200", "A5101", "A5102"].join(","),
        params['cdCat01'] = cat.join(',') if cat.instance_of?(Array)
        # cdTime: ["1981100000", "1982100000" ,"1984100000"].join(","),
        params['cdTime'] = time.join(',') if time.instance_of?(Array)

        URI.parse("#{BASE_URL}?#{URI.encode_www_form(params)}")
      end

      def self.extract_def(data, id)
        rec = data['GET_STATS_DATA']['STATISTICAL_DATA']\
        ['CLASS_INF']['CLASS_OBJ']
        rec.select { |x| x['@id'] == id }
      end

      def self.index_def(data_def)
        unless data_def.first['CLASS'].instance_of?(Array)
          # convert to array when number of element is 1
          data_def.first['CLASS'] = [data_def.first['CLASS']]
        end
        Hash[*data_def.first['CLASS'].map { |x| [x['@code'], x] }.flatten]
      end

      def self.get_values(data)
        data['GET_STATS_DATA']['STATISTICAL_DATA']['DATA_INF']['VALUE']
      end

      def initialize( stats_data_id,
                      area: nil, cat: nil, time: nil,
                      skip_level: [1],
                      skip_parent_area: true,
                      skip_child_area: false,
                      skip_nil_column: true,
                      skip_nil_row: false,
                      time_range: nil)
        @app_id = Estat.app_id
        if @app_id.nil? || @app_id.empty?
          raise ArgumentError, 'Please set app_id via `Datasets::Estat.configure` method'
        end

        super()

        @metadata.id = 'estat-api-2.1'
        @metadata.name = 'e-Stat API 2.1'
        @metadata.url = BASE_URL
        @metadata.description = 'e-Stat API 2.1'

        @stats_data_id = stats_data_id
        @area = area
        @cat = cat
        @time = time
        @skip_level = skip_level
        @skip_child_area = skip_child_area
        @skip_parent_area = skip_parent_area
        @skip_nil_column = skip_nil_column
        @skip_nil_row = skip_nil_row
        @time_range = time_range
      end

      def each
        url = EstatAPI.generate_url(@app_id,
                                    @stats_data_id,
                                    area: @area,
                                    cat: @cat,
                                    time: @time)
        json_data = fetch_data(url)
        index_data(json_data)
        return to_enum(__method__) unless block_given?

        # create rows
        @areas.each do |a_key, a_value|
          rows = []
          @timetables.reject { |_key, x| x[:skip] }.each do |st_key, _st_value|
            row = []
            @columns.reject { |_key, x| x[:skip] }.each do |c_key, _c_value|
              row << @indexed_data[st_key][a_key][c_key]
            rescue NoMethodError
              row << nil
            end
            rows << row
          end
          next unless rows.count(nil).zero?

          yield(Record.new(a_key, a_value['@name'], rows.flatten))
        end
      end

      private

      def fetch_data(url)
        # download
        option_hash = Digest::MD5.hexdigest(url.to_s)
        base_name = "estat-#{option_hash}.json"
        data_path = cache_dir_path + base_name
        download(data_path, url.to_s) unless data_path.exist?

        # parse json
        json_data = File.open(data_path) do |io|
          JSON.parse(io.read)
        end
        json_data
      end

      def index_data(json_data)
        # re-index data

        # table_def = EstatAPI.extract_def(json_data, "tab")
        timetable_def = EstatAPI.extract_def(json_data, 'time')
        column_def = EstatAPI.extract_def(json_data, 'cat01')
        area_def = EstatAPI.extract_def(json_data, 'area')

        # p table_def.map { |x| x["@name"] }
        @timetables = EstatAPI.index_def(timetable_def)
        @columns = EstatAPI.index_def(column_def)
        @areas = EstatAPI.index_def(area_def)

        # apply time_range to timetables
        if @time_range.instance_of?(Range)
          @timetables.select! { |k, _v| @timetables.keys[@time_range].include? k }
        end

        @indexed_data = Hash[*@timetables.keys.map { |x| [x, {}] }.flatten]
        EstatAPI.get_values(json_data).each do |row|
          next unless @timetables.key?(row['@time'])

          oldhash = @indexed_data[row['@time']][row['@area']]
          oldhash = {} if oldhash.nil?
          newhash = oldhash.merge(row['@cat01'] => row['$'].to_f)
          @indexed_data[row['@time']][row['@area']] = newhash
        end

        skip_areas
        skip_nil_column
        @schema = create_header
      end

      def skip_areas
        # skip levels
        @areas.reject! { |_key, x| @skip_level.include? x['@level'].to_i }

        # skip area that has children
        if @skip_parent_area
          # inspect hieralchy of areas
          @areas.each do |_a_key, a_value|
            next unless @areas.key? a_value['@parentCode']

            @areas[a_value['@parentCode']][:has_children] = true
          end
          # filter areas without children
          @areas.reject! { |_key, x| x[:has_children] }
        end

        # skip child area
        if @skip_child_area
          @areas.reject! { |_a_key, a_value| (@areas.key? a_value['@parentCode']) }
        end
      end

      def skip_nil_column
        # filter timetables and columns
        if @skip_nil_column
          @areas.each do |a_key, _a_value|
            @timetables.each do |st_key, st_value|
              unless @indexed_data[st_key].key?(a_key)
                st_value[:skip] = true
                next
              end
              @columns.each do |c_key, c_value|
                # p @indexed_data[st_key][a_key][c_key] == nil
                unless @indexed_data[st_key][a_key].key?(c_key)
                  c_value[:skip] = true
                  next
                end
              end
            end
          end
        end
      end

      def create_header
        schema = []
        @timetables.reject { |_key, x| x[:skip] }.each do |_st_key, st_value|
          @columns.reject { |_key, x| x[:skip] }.each do |_c_key, c_value|
            schema << "#{st_value['@name']}_#{c_value['@name']}"
          end
        end
        schema
      end
    end
  end
end
