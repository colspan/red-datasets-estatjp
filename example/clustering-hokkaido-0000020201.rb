#!/usr/bin/env ruby -Ku

# clustering communes in Hokkaido by statistics of population
# e-Stat 0000020201 Ａ　人口・世帯

require 'bundler/setup'
require 'kmeans-clusterer'
require 'daru'

require 'estatjp'
require_relative 'estat-config'

estat = Datasets::Estat::EstatAPI.new(
  '0000020201', # Ａ　人口・世帯
  skip_parent_area: true,
  skip_child_area: false,
  skip_nil_column: true,
  skip_nil_row: false,
  cat: ['A1101'] # A1101_人口総数
)

# prepare for clustering
indices = []
rows = []
map_id_name = {}
estat.each do |record|
  # 北海道に限定する
  next unless record.id.to_s.start_with? '01'

  indices << record.id
  rows << record.values
  map_id_name[record.id] = record.name
end

# create dataframe
df = Daru::DataFrame.rows(rows, order: estat.schema, index: indices)

# rate of change
rate_of_change_df = df / df[df.vectors.to_a[0]]

# do clustering
k = 12 # Number of clusters to find
kmeans = KMeansClusterer.run(
  k,
  rate_of_change_df.to_matrix.to_a,
  labels: rate_of_change_df.index.to_a,
  runs: 100
)
puts %w[id name cluster].join(',')
kmeans.clusters.each do |cluster|
  cluster.points.each do |p|
    puts [p.label, map_id_name[p.label], cluster.id].join(',')
  end
end
