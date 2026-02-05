# frozen_string_literal: true

source 'https://rubygems.org'

gem 'activesupport', '>= 7'
gem 'lcsort'
gem 'library_stdnums', '~> 1.6'
gem 'marc', '~> 1.2'
gem 'nokogiri', '~> 1.15'
gem 'rake', '~> 13.0'
gem 'upennlib-rubocop', require: false

group :test, :development do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'rspec', '~> 3.12'
end

group :test do
  gem 'simplecov', '~> 0.22'
end

group :development do
  gem 'puma'
  gem 'rackup'
  gem 'yard', '~> 0.9'
end
