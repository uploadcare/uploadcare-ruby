# frozen_string_literal: true

require 'bundler/setup'
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
