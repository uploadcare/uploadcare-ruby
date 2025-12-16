# frozen_string_literal: true

require 'spec_helper'
require 'logger'

RSpec.describe Uploadcare::Configuration do
  subject(:config) { described_class.new }
  let(:default_values) do
    { public_key: ENV.fetch('UPLOADCARE_PUBLIC_KEY', ''),
      secret_key: ENV.fetch('UPLOADCARE_SECRET_KEY', ''),
      auth_type: 'Uploadcare',
      multipart_size_threshold: 100 * 1024 * 1024,
      rest_api_root: 'https://api.uploadcare.com',
      upload_api_root: 'https://upload.uploadcare.com',
      max_request_tries: 100,
      base_request_sleep: 1,
      max_request_sleep: 60.0,
      sign_uploads: false,
      upload_signature_lifetime: 30 * 60,
      max_throttle_attempts: 5,
      upload_threads: 2,
      framework_data: '',
      file_chunk_size: 100 }
  end
  let(:new_values) do
    {
      public_key: 'test_public_key',
      secret_key: 'test_secret_key',
      auth_type: 'Uploadcare.Simple',
      multipart_size_threshold: 50 * 1024 * 1024,
      rest_api_root: 'https://api.example.com',
      upload_api_root: 'https://upload.example.com',
      max_request_tries: 5,
      base_request_sleep: 2,
      max_request_sleep: 30.0,
      sign_uploads: true,
      upload_signature_lifetime: 60 * 60,
      max_throttle_attempts: 10,
      upload_threads: 4,
      framework_data: 'Rails/6.0.0',
      file_chunk_size: 200
    }
  end

  it 'has configurable default values' do
    default_values.each do |attribute, expected_value|
      actual_value = config.send(attribute)
      if expected_value.is_a?(RSpec::Matchers::BuiltIn::BaseMatcher)
        expect(actual_value).to expected_value
      else
        expect(actual_value).to eq(expected_value)
      end
    end

    new_values.each do |attribute, new_value|
      config.send("#{attribute}=", new_value)
      expect(config.send(attribute)).to eq(new_value)
    end
  end
end
