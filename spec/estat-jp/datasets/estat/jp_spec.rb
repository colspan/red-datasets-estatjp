RSpec.describe Datasets::Estat do
  it 'has a version number' do
    expect(Datasets::Estat::VERSION).not_to be nil
  end

  it 'check configuration' do
    expect do
      Datasets::Estat::EstatAPI.new('test')
    end.to raise_error(ArgumentError)
    Datasets::Estat.configure do |config|
      config.app_id = 'test'
    end
    expect do
      Datasets::Estat::EstatAPI.new('test')
    end.not_to raise_error
  end

  it 'url generator test' do
    app_id = 'abcdef'
    stats_data_id = '000000'
    url = Datasets::Estat::EstatAPI.generate_url(app_id, stats_data_id)
    expect(url.to_s).to eq 'http://api.e-stat.go.jp/rest/2.1/app/json/getStatsData?appId=abcdef&lang=J&statsDataId=000000&metaGetFlg=Y&cntGetFlg=N&sectionHeaderFlg=1'
  end
end

## MEMO fetching actual app_id from environment
# begin
#   app_id = ENV.fetch('ESTAT_APPID')
# rescue KeyError
#   raise KeyError, 'Please run `export ESTAT_APPID=<e-stat api key>`'
# end
