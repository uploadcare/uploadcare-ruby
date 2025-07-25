# frozen_string_literal: true

require 'simplecov'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.single_report_path = 'coverage/lcov.info'
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
                                                                 SimpleCov::Formatter::HTMLFormatter,
                                                                 SimpleCov::Formatter::LcovFormatter
                                                               ])

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'

  add_group 'Clients', 'lib/uploadcare/clients'
  add_group 'Resources', 'lib/uploadcare/resources'
  add_group 'Middleware', 'lib/uploadcare/middleware'
  add_group 'Signed URL Generators', 'lib/uploadcare/signed_url_generators'

  track_files 'lib/**/*.rb'

  minimum_coverage 80
  minimum_coverage_by_file 50
end

require 'bundler/setup'
require 'byebug'
require 'webmock/rspec'
require 'uploadcare'
Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:all) do
    Uploadcare::Configuration.new(
      public_key: 'some_public_key',
      secret_key: 'some_secret_key',
      auth_type: 'Uploadcare.Simple',
      rest_api_root: 'https://api.uploadcare.com'
    )
  end
end
