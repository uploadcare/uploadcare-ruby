# frozen_string_literal: true

source 'https://rubygems.org'

group :development, :test do
  # Ruby 3.4+ stopped shipping some stdlib components as default gems.
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.4')
    gem 'base64', require: false
    gem 'cgi', require: false
  end

  # Ruby 4.1+ removes tsort from default gems.
  gem('tsort', require: false) if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('4.1')

  gem 'byebug'
  gem 'dotenv', '~> 3.2' # For running examples with .env file
  gem 'rake'
  gem 'redcarpet'
  gem 'rspec'
  gem 'rubocop'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webmock'
  gem 'yard'
end

# Specify your gem's dependencies in uploadcare-ruby.gemspec
gemspec
