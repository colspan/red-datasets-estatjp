#!/usr/bin/env ruby -Ku

# clustering communes in Hokkaido by statistics of economy
# e-Stat 0000020203 C 経済基盤

require 'bundler/setup'
require 'kmeans-clusterer'

require 'estatjp'
require_relative 'estatjp-config'

estat = Datasets::Estatjp::JsonAPI.new(
  '0000020203', # Ｃ　経済基盤
  skip_parent_area: false,
  skip_child_area: true,
  skip_nil_column: false,
  skip_nil_row: true,
  cat: %w[C120110 C120120], # C120110_課税対象所得, C120120_納税義務者数（所得割）
  time_range: -4..-1 # 2013〜2016年 (末尾から4〜1件目)
)

# prepare for clustering
labels = []
rows = []
map_id_name = {}
estat.each do |record|
  # 北海道に限定する
  next unless record.id.to_s.start_with? '01'
  labels << record.id
  rows << record.values
  map_id_name[record.id] = record.name
end

puts estat.schema

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
