# red-datasets-estatjp
e-stat API wrapper compliant with red-datasets

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'red-datasets-estatjp'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install red-datasets-estatjp

## Usage

### Get e-Stat API's App ID

See detail at [APIの使い方(How to use e-Stat API)](https://www.e-stat.go.jp/api/api-dev/how_to_use) (Japanese only).

### Configuration

```ruby
require 'estatjp'

Datasets::Estatjp.configure do |config|
  # put your App ID for e-Stat app_id
  config.app_id = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
end
```

See [example of configuration](example/estat-config.rb.example).

### Calling API and fetching data

```ruby
require 'estatjp'

# call
estat = Datasets::Estatjp::JsonAPI.new(
  '0000020201', # Ａ　人口・世帯
  skip_parent_area: true,
  skip_child_area: false,
  skip_nil_column: true,
  skip_nil_row: false,
  cat: ['A1101'], # A1101_人口総数
)

# fetch
estat.each do |record|
  p record
end
```

## Example

```bash
# prepare environment for examples
$ export BUNDLE_GEMFILE='Gemfile.local' # use of alternative Gemfile for examples
$ bundle install

# clustering examples
## clustering all communes by all available columns
$ bundle exec ruby example/clustering-all.rb
## clustering communes in Hokkaido by statistics of population (人口・世帯 0000020201)
$ bundle exec ruby example/clustering-hokkaido-0000020201.rb
## clustering communes in Hokkaido by statistics of economy (経済基盤 0000020203)
$ bundle exec ruby example/clustering-hokkaido-0000020203.rb

# after execution
$ export BUNDLE_GEMFILE= # unset use of Gemfile.local
$ bundle install
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Generating documents

```
$ bundle exec yardoc
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/colspan/red-datasets-estatjp.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
