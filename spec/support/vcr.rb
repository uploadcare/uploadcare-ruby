# frozen_string_literal: true

require 'rubygems'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('<uploadcare_public_key>') { Uploadcare.configuration.public_key }
  config.filter_sensitive_data('<uploadcare_secret_key>') { Uploadcare.configuration.secret_key }
  config.before_record do |i|
    if i.request.body && i.request.body.size > 1024 * 1024
      i.request.body = "Big string (#{i.request.body.size / (1024 * 1024)}) MB"
    end
  end
  config.configure_rspec_metadata!
end
