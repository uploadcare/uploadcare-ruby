# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/bin/'
  add_filter '/examples/'
  add_filter '/api_examples/'

  add_group 'Api', 'lib/uploadcare/api'
  add_group 'Internal', 'lib/uploadcare/internal'
  add_group 'Resources', 'lib/uploadcare/resources'
  add_group 'Collections', 'lib/uploadcare/collections'
  add_group 'Operations', 'lib/uploadcare/operations'
  add_group 'Core', 'lib/uploadcare'

  minimum_coverage 90
end

require 'byebug'
require 'webmock/rspec'
require 'uploadcare'
Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].each { |f| require f }

RSpec.configure do |config|
  include Uploadcare::Exception

  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:all) do
    Uploadcare.configure do |c|
      c.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'demopublickey')
      c.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'demosecretkey')
      c.auth_type = 'Uploadcare.Simple'
      c.rest_api_root = 'https://api.uploadcare.com'
    end
  end
end
