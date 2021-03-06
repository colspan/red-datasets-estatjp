lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'estatjp/version'

Gem::Specification.new do |spec|
  spec.name = 'red-datasets-estatjp'
  spec.version = Datasets::Estatjp::VERSION
  spec.authors = ['Kunihiko MIYOSHI']
  spec.email = ['miyoshik@gmail.com']

  spec.summary = 'e-Stat API wrapper comform to Red Data Tools'
  spec.description = 'e-Stat API wrapper comform to Red Data Tools.'
  spec.homepage = 'https://github.com/colspan/red-datasets-estatjp'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
