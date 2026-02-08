# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'

# Start SimpleCov
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/bin/'
  add_filter '/examples/'
  add_filter '/api_examples/'

  add_group 'Clients', 'lib/uploadcare/clients'
  add_group 'Resources', 'lib/uploadcare/resources'
  add_group 'Core', 'lib/uploadcare'

  # Set minimum coverage goal
  minimum_coverage 95
end

require 'byebug'
require 'webmock/rspec'
require 'uploadcare'
Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].each { |f| require f }

RSpec.configure do |config|
  include Uploadcare::Exception

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
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
