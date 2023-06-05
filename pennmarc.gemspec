# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'pennmarc'
  s.version     = '0.0.1'
  s.summary     = 'Penn Libraries Catalog MARC parsing wisdom for cross-project usage'
  s.description = 'Penn Libraries Catalog MARC parsing wisdom for cross-project usage'
  s.authors     = ['Mike Kanning']
  s.email       = 'mkanning@upenn.edu'
  s.files       = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  s.homepage    = 'https://gitlab.library.upenn.edu/dld/catalog/pennmarc'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.2'

  s.add_dependency 'marc'

  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'upennlib-rubocop'
end
