require "datasets"

require "digest/md5"
require "net/http"
require "uri"
require "json"

module Datasets
  Record = Struct.new(:id, :name, :values)

  class Estat < Dataset
    attr_accessor :areas, :timetables, :schema

    def initialize(app_id, stats_data_id,
                   area: nil, cat: nil, time: nil,
                   skip_level: [1],
                   skip_parent_area: true,
                   skip_child_area: false,
                   skip_nil_column: true,
                   skip_nil_row: false,
                   time_range: nil)
      if app_id.length == 0
        raise ArgumentError, "Please set app_id"
      end

      super()

      base_url = "http://api.e-stat.go.jp/rest/2.1/app/json/getStatsData"

      # set api parameters
      params = {
        appId: app_id,
        lang: "J",
        statsDataId: stats_data_id, # 表番号
        metaGetFlg: "Y",
        cntGetFlg: "N",
        sectionHeaderFlg: "1",
      }
      # cdArea: ["01105", "01106"].join(","), # 地域
      params["cdArea"] = area.join(",") if area.instance_of?(Array)
      # cdCat01: ["A2101", "A210101", "A210102", "A2201", "A2301", "A4101", "A4200", "A5101", "A5102"].join(","),
      params["cdCat01"] = cat.join(",") if cat.instance_of?(Array)
      # cdTime: ["1981100000", "1982100000" ,"1984100000"].join(","),
      params["cdTime"] = time.join(",") if time.instance_of?(Array)

      @url = URI.parse("#{base_url}?#{URI.encode_www_form(params)}")

      @metadata.id = "estat-api-2.1"
      @metadata.name = "e-Stat API 2.1"
      @metadata.url = base_url
      @metadata.description = "e-Stat API 2.1"

      # download
      option_hash = Digest::MD5.hexdigest(params.to_s)
      base_name = "estat-#{option_hash}.json"
      data_path = cache_dir_path + base_name
      unless data_path.exist?
        download(data_path, "#{@url}")
      end

      # parse json
      json_data = open(data_path) do |io|
        JSON.load(io)
      end

      @skip_level = skip_level
      @skip_child_area = skip_child_area
      @skip_parent_area = skip_parent_area
      @skip_nil_column = skip_nil_column
      @skip_nil_row = skip_nil_row
      @time_range = time_range

      index_data(json_data)
    end

    def each(&block)
      return to_enum(__method__) unless block_given?

      # create rows
      @areas.each do |a_key, a_value|
        rows = []
        @timetables.select { |key, x| !x[:skip] }.each do |st_key, st_value|
          row = []
          @columns.select { |key, x| !x[:skip] }.each do |c_key, c_value|
            begin
              row << @indexed_data[st_key][a_key][c_key]
            rescue NoMethodError
              row << nil
            end
          end
          rows << row
        end
        next unless rows.count(nil) == 0
        yield(Record.new(a_key, a_value["@name"], rows.flatten))
      end
    end

    private

    def extract_def(data, id)
      data["GET_STATS_DATA"]["STATISTICAL_DATA"]["CLASS_INF"]["CLASS_OBJ"].select { |x| x["@id"] == id }
    end

    def index_def(data_def)
      if not data_def.first["CLASS"].instance_of?(Array)
        # convert to array when number of element is 1
        data_def.first["CLASS"] = [data_def.first["CLASS"]]
      end
      Hash[*data_def.first["CLASS"].map { |x| [x["@code"], x] }.flatten]
    end

    def get_values(data)
      data["GET_STATS_DATA"]["STATISTICAL_DATA"]["DATA_INF"]["VALUE"]
    end

    def index_data(json_data)

      # table_def = extract_def(json_data, "tab")
      timetable_def = extract_def(json_data, "time")
      column_def = extract_def(json_data, "cat01")
      area_def = extract_def(json_data, "area")

      # p table_def.map { |x| x["@name"] }
      @timetables = index_def(timetable_def)
      @columns = index_def(column_def)
      @areas = index_def(area_def)

      # apply time_range to timetables
      if @time_range.instance_of?(Range)
        @timetables.select! { |k, v| @timetables.keys[@time_range].include? k }
      end

      @indexed_data = Hash[*@timetables.keys.map { |x| [x, {}] }.flatten]
      get_values(json_data).each do |row|
        next unless @timetables.keys.include? row["@time"]
        oldhash = @indexed_data[row["@time"]][row["@area"]]
        oldhash = {} if oldhash == nil
        newhash = oldhash.merge({row["@cat01"] => row["$"].to_f})
        @indexed_data[row["@time"]][row["@area"]] = newhash
      end

      # skip levels
      @areas.select! { |key, x| !@skip_level.include? x["@level"].to_i }

      # skip area that has children
      if @skip_parent_area
        # inspect hieralchy of areas
        @areas.each do |a_key, a_value|
          next unless @areas.key? a_value["@parentCode"]
          @areas[a_value["@parentCode"]][:has_children] = true
        end
        # filter areas without children
        @areas.select! { |key, x| !x[:has_children] }
      end

      # skip child area
      if @skip_child_area
        @areas.select! { |a_key, a_value| !(@areas.key? a_value["@parentCode"]) }
      end

      # filter timetables and columns
      if @skip_nil_column
        @areas.each do |a_key, a_value|
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

      # create header
      @schema = []
      @timetables.select { |key, x| !x[:skip] }.each do |st_key, st_value|
        @columns.select { |key, x| !x[:skip] }.each do |c_key, c_value|
          @schema << "#{st_value["@name"]}_#{c_value["@name"]}"
        end
      end
    end
  end
end
