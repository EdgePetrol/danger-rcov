# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rcov/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'danger-rcov'
  spec.version       = Rcov::VERSION
  spec.authors       = ['Guilherme Pereira']
  spec.email         = ['guilhermepereira@edgepetrol.com']
  spec.description   = %(Plugin that allows code coverage print)
  spec.summary       = %(Plugin that allows code coverage print)
  spec.homepage      = 'https://github.com/EdgePetrol/danger-rcov'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.4.0'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'circle_ci_wrapper', '~> 0.0.1'
  spec.add_runtime_dependency 'danger-plugin-api', '~> 1.0'

  # General ruby development
  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'guard', '~> 2.14'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'
  spec.add_development_dependency 'listen', '3.0.7'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-json'
  spec.add_development_dependency 'simplecov-shield-json', '~> 0.0.4'
  spec.add_development_dependency 'yard'
end
