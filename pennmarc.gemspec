# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'pennmarc'
  s.version     = PennMARC::VERSION
  s.summary     = 'Penn Libraries Catalog MARC parsing wisdom for cross-project usage'
  s.description = 'This gem provides methods for parsing a Penn Libraries MARCXML record into string, array and date
                   objects for use in discovery or preservation applications.'
  s.authors     = ['Mike Kanning', 'Amrey Mathurin', 'Patrick Perkins']
  s.email       = 'mkanning@upenn.edu'
  s.files       = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  s.homepage    = 'https://gitlab.library.upenn.edu/dld/catalog/pennmarc'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.2'

  s.add_dependency 'activesupport', '~> 7'
  s.add_dependency 'library_stdnums', '~> 1.6'
  s.add_dependency 'marc', '~> 1.2'
  s.add_dependency 'nokogiri', '~> 1.15'

  s.metadata['rubygems_mfa_required'] = 'true'
end
