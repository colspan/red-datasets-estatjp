RSpec.describe Datasets::Estatjp do
  it 'has a version number' do
    expect(Datasets::Estatjp::VERSION).not_to be nil
  end

  it 'check configuration' do
    # error if app_id is undefined
    expect do
      Datasets::Estatjp::JSONAPI.new('test')
    end.to raise_error(ArgumentError)

    # ok if app_id is set by ENV
    ENV['ESTATJP_APPID'] = 'test_by_env'
    expect do
      obj = Datasets::Estatjp::JSONAPI.new('test')
      expect(obj.app_id).to eq 'test_by_env'
    end.not_to raise_error
    ENV['ESTATJP_APPID'] = nil
    
    # ok if app_id is set by configure method
    Datasets::Estatjp.configure do |config|
      config.app_id = 'test_by_method'
    end
    expect do
      obj = Datasets::Estatjp::JSONAPI.new('test')
      expect(obj.app_id).to eq 'test_by_method'
    end.not_to raise_error
    Datasets::Estatjp.app_id = nil

    # ok if app_id is set by ENV
    ENV['ESTATJP_APPID'] = 'test_by_env2'
    expect do
      obj = Datasets::Estatjp::JSONAPI.new('test')
      expect(obj.app_id).to eq 'test_by_env2'
    end.not_to raise_error
    ENV['ESTATJP_APPID'] = nil

    
  end

  it 'url generator test' do
    app_id = 'abcdef'
    stats_data_id = '000000'
    base_url = 'http://testurl/rest/2.1/app/json/getStatsData'
    url = Datasets::Estatjp::JSONAPI.generate_url(base_url, app_id, stats_data_id)
    expect(url.to_s).to eq 'http://testurl/rest/2.1/app/json/getStatsData?appId=abcdef&lang=J&statsDataId=000000&metaGetFlg=Y&cntGetFlg=N&sectionHeaderFlg=1'
  end
end

## MEMO fetching actual app_id from environment
# begin
#   app_id = ENV.fetch('ESTAT_APPID')
# rescue KeyError
#   raise KeyError, 'Please run `export ESTAT_APPID=<e-stat api key>`'
# end
