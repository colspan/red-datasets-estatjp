#!/usr/bin/env ruby -Ku

# clustering all communes by all available columns

require 'bundler/setup'
require 'kmeans-clusterer'

require 'estat-jp'
require_relative 'estat-config'

# 市区町村データ 基礎データ（廃置分合処理済）
# https://www.e-stat.go.jp/stat-search/database?page=1&layout=datalist&toukei=00200502&tstat=000001111376&cycle=8&tclass1=000001111380&second=1&second2=1
estat_datasets_essential = [
  { data_id: '0000020201', name: 'Ａ　人口・世帯' },
  { data_id: '0000020202', name: 'Ｂ　自然環境' },
  { data_id: '0000020203', name: 'Ｃ　経済基盤' },
  { data_id: '0000020204', name: 'Ｄ　行政基盤' },
  { data_id: '0000020205', name: 'Ｅ　教育' },
  { data_id: '0000020206', name: 'Ｆ　労働' },
  { data_id: '0000020207', name: 'Ｇ　文化・スポーツ' },
  { data_id: '0000020208', name: 'Ｈ　居住' },
  { data_id: '0000020209', name: 'Ｉ　健康・医療' },
  { data_id: '0000020210', name: 'Ｊ　福祉・社会保障' },
  { data_id: '0000020211', name: 'Ｋ　安全' }
]

# 市区町村データ 社会生活統計指標（廃置分合処理済）
# https://www.e-stat.go.jp/stat-search/database?page=1&layout=datalist&toukei=00200502&tstat=000001111376&cycle=8&tclass1=000001111381&second=1&second2=1
estat_datasets_social_life = [
  { data_id: '0000020301', name: 'Ａ　人口・世帯' },
  { data_id: '0000020302', name: 'Ｂ　自然環境' },
  { data_id: '0000020303', name: 'Ｃ　経済基盤' },
  { data_id: '0000020304', name: 'Ｄ　行政基盤' },
  { data_id: '0000020305', name: 'Ｅ　教育' },
  { data_id: '0000020306', name: 'Ｆ　労働' },
  { data_id: '0000020307', name: 'Ｇ　文化・スポーツ' },
  { data_id: '0000020308', name: 'Ｈ　居住' },
  { data_id: '0000020309', name: 'Ｉ　健康・医療' },
  { data_id: '0000020310', name: 'Ｊ　福祉・社会保障' },
  { data_id: '0000020311', name: 'Ｋ　安全' }
]

# read and join datasets
schema = []
joined_data = {}
map_id_name = {}
[estat_datasets_essential, estat_datasets_social_life].each do |dataset_def|
  dataset_def.each do |dataset|
    estat = Datasets::Estat::EstatAPI.new(dataset[:data_id], skip_nil_column: true)
    schema << estat.schema
    estat.each do |record|
      joined_data[record.id] = [] unless joined_data.key? record.id
      joined_data[record.id] += record.values
      map_id_name[record.id] = record.name
    end
  end
end

# prepare for clustering
labels = []
rows = []
joined_data.each do |key, values|
  labels << key
  rows << values
end

# do clustering
k = 12 # Number of clusters to find
kmeans = KMeansClusterer.run k, rows, labels: labels, runs: 100
puts %w[id name cluster].join(',')
kmeans.clusters.each do |cluster|
  # puts "Cluster #{cluster.id}"
  # puts "Center of Cluster: #{cluster.centroid}"
  # puts "Cities in Cluster: " + cluster.points.map { |c| c.label }.join(",")
  cluster.points.each do |p|
    puts [p.label, map_id_name[p.label], cluster.id].join(',')
  end
end
