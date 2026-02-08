# frozen_string_literal: true

source 'https://rubygems.org'

# Ruby 3.4+ and 4.0+ compatibility - these gems are no longer in stdlib
gem 'base64'
gem 'benchmark' # Required for Ruby 4.0+ compatibility
gem 'bigdecimal'
gem 'cgi' # Required for Ruby 4.0+ compatibility
gem 'mutex_m'

group :development, :test do
  gem 'byebug'
  gem 'dotenv', '~> 3.2' # For running examples with .env file
  gem 'rake'
  gem 'rspec'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'simplecov', require: false
  gem 'tsort', require: false
  gem 'vcr'
  gem 'webmock'
end

# Specify your gem's dependencies in uploadcare-ruby.gemspec
gemspec
