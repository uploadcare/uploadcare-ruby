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

  describe 'initialization' do
    it 'has configurable default values' do
      default_values.each do |attribute, expected_value|
        actual_value = config.send(attribute)
        if expected_value.is_a?(RSpec::Matchers::BuiltIn::BaseMatcher)
          expect(actual_value).to expected_value
        else
          expect(actual_value).to eq(expected_value)
        end
      end
    end

    it 'allows setting custom values' do
      new_values.each do |attribute, new_value|
        config.send("#{attribute}=", new_value)
        expect(config.send(attribute)).to eq(new_value)
      end
    end
  end

  describe 'attribute accessors' do
    describe '#public_key' do
      it 'defaults to environment variable' do
        expect(config.public_key).to eq(ENV.fetch('UPLOADCARE_PUBLIC_KEY', ''))
      end

      it 'can be set to custom value' do
        config.public_key = 'pub_custom_key'
        expect(config.public_key).to eq('pub_custom_key')
      end

      it 'accepts nil value' do
        config.public_key = nil
        expect(config.public_key).to be_nil
      end

      it 'accepts empty string' do
        config.public_key = ''
        expect(config.public_key).to eq('')
      end
    end

    describe '#secret_key' do
      it 'defaults to environment variable' do
        expect(config.secret_key).to eq(ENV.fetch('UPLOADCARE_SECRET_KEY', ''))
      end

      it 'can be set to custom value' do
        config.secret_key = 'secret_custom_key'
        expect(config.secret_key).to eq('secret_custom_key')
      end

      it 'accepts nil value' do
        config.secret_key = nil
        expect(config.secret_key).to be_nil
      end
    end

    describe '#auth_type' do
      it 'defaults to Uploadcare' do
        expect(config.auth_type).to eq('Uploadcare')
      end

      it 'accepts Uploadcare.Simple' do
        config.auth_type = 'Uploadcare.Simple'
        expect(config.auth_type).to eq('Uploadcare.Simple')
      end

      it 'accepts custom auth types' do
        config.auth_type = 'CustomAuth'
        expect(config.auth_type).to eq('CustomAuth')
      end
    end

    describe '#multipart_size_threshold' do
      it 'defaults to 100MB' do
        expect(config.multipart_size_threshold).to eq(100 * 1024 * 1024)
      end

      it 'accepts custom byte values' do
        config.multipart_size_threshold = 50 * 1024 * 1024
        expect(config.multipart_size_threshold).to eq(50 * 1024 * 1024)
      end

      it 'accepts zero value' do
        config.multipart_size_threshold = 0
        expect(config.multipart_size_threshold).to eq(0)
      end
    end

    describe '#rest_api_root' do
      it 'defaults to production API URL' do
        expect(config.rest_api_root).to eq('https://api.uploadcare.com')
      end

      it 'accepts custom API URLs' do
        config.rest_api_root = 'https://api.staging.uploadcare.com'
        expect(config.rest_api_root).to eq('https://api.staging.uploadcare.com')
      end

      it 'accepts URLs with paths' do
        config.rest_api_root = 'https://api.example.com/uploadcare'
        expect(config.rest_api_root).to eq('https://api.example.com/uploadcare')
      end
    end

    describe '#upload_api_root' do
      it 'defaults to production upload URL' do
        expect(config.upload_api_root).to eq('https://upload.uploadcare.com')
      end

      it 'accepts custom upload URLs' do
        config.upload_api_root = 'https://upload.staging.uploadcare.com'
        expect(config.upload_api_root).to eq('https://upload.staging.uploadcare.com')
      end
    end

    describe '#max_request_tries' do
      it 'defaults to 100' do
        expect(config.max_request_tries).to eq(100)
      end

      it 'accepts custom retry counts' do
        config.max_request_tries = 5
        expect(config.max_request_tries).to eq(5)
      end

      it 'accepts zero (no retries)' do
        config.max_request_tries = 0
        expect(config.max_request_tries).to eq(0)
      end
    end

    describe '#base_request_sleep' do
      it 'defaults to 1 second' do
        expect(config.base_request_sleep).to eq(1)
      end

      it 'accepts fractional seconds' do
        config.base_request_sleep = 0.5
        expect(config.base_request_sleep).to eq(0.5)
      end
    end

    describe '#max_request_sleep' do
      it 'defaults to 60 seconds' do
        expect(config.max_request_sleep).to eq(60.0)
      end

      it 'accepts custom maximum sleep times' do
        config.max_request_sleep = 30.0
        expect(config.max_request_sleep).to eq(30.0)
      end
    end

    describe '#sign_uploads' do
      it 'defaults to false' do
        expect(config.sign_uploads).to be false
      end

      it 'accepts true value' do
        config.sign_uploads = true
        expect(config.sign_uploads).to be true
      end

      it 'accepts falsy values' do
        config.sign_uploads = false
        expect(config.sign_uploads).to be false

        config.sign_uploads = nil
        expect(config.sign_uploads).to be_falsy
      end
    end

    describe '#upload_signature_lifetime' do
      it 'defaults to 30 minutes' do
        expect(config.upload_signature_lifetime).to eq(30 * 60)
      end

      it 'accepts custom lifetimes' do
        config.upload_signature_lifetime = 60 * 60
        expect(config.upload_signature_lifetime).to eq(60 * 60)
      end
    end

    describe '#max_throttle_attempts' do
      it 'defaults to 5' do
        expect(config.max_throttle_attempts).to eq(5)
      end

      it 'accepts custom attempt counts' do
        config.max_throttle_attempts = 10
        expect(config.max_throttle_attempts).to eq(10)
      end

      it 'accepts 1 (no retries)' do
        config.max_throttle_attempts = 1
        expect(config.max_throttle_attempts).to eq(1)
      end
    end

    describe '#upload_threads' do
      it 'defaults to 2' do
        expect(config.upload_threads).to eq(2)
      end

      it 'accepts custom thread counts' do
        config.upload_threads = 8
        expect(config.upload_threads).to eq(8)
      end

      it 'accepts 1 (sequential)' do
        config.upload_threads = 1
        expect(config.upload_threads).to eq(1)
      end
    end

    describe '#framework_data' do
      it 'defaults to empty string' do
        expect(config.framework_data).to eq('')
      end

      it 'accepts framework information' do
        config.framework_data = 'Rails/7.0.0'
        expect(config.framework_data).to eq('Rails/7.0.0')
      end

      it 'accepts detailed framework data' do
        config.framework_data = 'Rails/7.0.0 (ruby-3.1.0)'
        expect(config.framework_data).to eq('Rails/7.0.0 (ruby-3.1.0)')
      end
    end

    describe '#file_chunk_size' do
      it 'defaults to 100' do
        expect(config.file_chunk_size).to eq(100)
      end

      it 'accepts custom chunk sizes' do
        config.file_chunk_size = 200
        expect(config.file_chunk_size).to eq(200)
      end
    end

    describe '#logger' do
      it 'has a default logger' do
        expect(config.logger).to be_a(Logger)
      end

      it 'accepts Logger instance' do
        logger = Logger.new(STDOUT)
        config.logger = logger
        expect(config.logger).to eq(logger)
      end

      it 'accepts custom logger objects' do
        custom_logger = double('custom_logger')
        config.logger = custom_logger
        expect(config.logger).to eq(custom_logger)
      end

      it 'accepts nil to disable logging' do
        config.logger = Logger.new(STDOUT)
        config.logger = nil
        expect(config.logger).to be_nil
      end
    end
  end

  describe 'edge cases and validation' do
    describe 'numeric attributes' do
      it 'handles negative values for retry settings' do
        config.max_request_tries = -1
        expect(config.max_request_tries).to eq(-1)
      end

      it 'handles very large threshold values' do
        large_threshold = 10 * 1024 * 1024 * 1024 # 10GB
        config.multipart_size_threshold = large_threshold
        expect(config.multipart_size_threshold).to eq(large_threshold)
      end

      it 'handles fractional sleep values' do
        config.base_request_sleep = 1.5
        config.max_request_sleep = 120.75
        expect(config.base_request_sleep).to eq(1.5)
        expect(config.max_request_sleep).to eq(120.75)
      end
    end

    describe 'string attributes' do
      it 'handles very long strings' do
        long_key = 'a' * 1000
        config.public_key = long_key
        expect(config.public_key).to eq(long_key)
      end

      it 'handles unicode characters' do
        unicode_data = 'Rails/7.0.0 🚀'
        config.framework_data = unicode_data
        expect(config.framework_data).to eq(unicode_data)
      end

      it 'handles URLs with special characters' do
        special_url = 'https://api-test.example.com:8080/v1/uploadcare?param=value&other=test'
        config.rest_api_root = special_url
        expect(config.rest_api_root).to eq(special_url)
      end
    end

    describe 'boolean attributes' do
      it 'handles truthy values for sign_uploads' do
        ['yes', 1, 'true', Object.new].each do |truthy_value|
          config.sign_uploads = truthy_value
          expect(config.sign_uploads).to be_truthy
        end
      end

      it 'handles falsy values for sign_uploads' do
        [false, nil].each do |falsy_value|
          config.sign_uploads = falsy_value
          expect(config.sign_uploads).to be_falsy
        end

        # Empty string and 'false' string are stored as-is
        ['', 'false'].each do |string_value|
          config.sign_uploads = string_value
          expect(config.sign_uploads).to eq(string_value)
        end
      end
    end
  end

  describe 'configuration chaining' do
    it 'allows method chaining for configuration' do
      result = config
               .tap { |c| c.public_key = 'pub_key' }
               .tap { |c| c.secret_key = 'secret_key' }
               .tap { |c| c.sign_uploads = true }

      expect(result).to eq(config)
      expect(config.public_key).to eq('pub_key')
      expect(config.secret_key).to eq('secret_key')
      expect(config.sign_uploads).to be true
    end
  end

  describe 'environment variable integration' do
    around do |example|
      original_public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', nil)
      original_secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', nil)

      example.run

      ENV['UPLOADCARE_PUBLIC_KEY'] = original_public_key
      ENV['UPLOADCARE_SECRET_KEY'] = original_secret_key
    end

    it 'reads public key from environment' do
      ENV['UPLOADCARE_PUBLIC_KEY'] = 'env_public_key'
      # Create new configuration to pick up environment variable
      new_config = described_class.new
      expect(new_config.public_key).to eq('env_public_key')
    end

    it 'reads secret key from environment' do
      ENV['UPLOADCARE_SECRET_KEY'] = 'env_secret_key'
      # Create new configuration to pick up environment variable
      new_config = described_class.new
      expect(new_config.secret_key).to eq('env_secret_key')
    end

    it 'handles missing environment variables' do
      ENV.delete('UPLOADCARE_PUBLIC_KEY')
      ENV.delete('UPLOADCARE_SECRET_KEY')
      new_config = described_class.new
      expect(new_config.public_key).to eq('')
      expect(new_config.secret_key).to eq('')
    end
  end

  describe 'instance vs class behavior' do
    it 'creates independent configuration instances' do
      config1 = described_class.new
      config2 = described_class.new

      config1.public_key = 'key1'
      config2.public_key = 'key2'

      expect(config1.public_key).to eq('key1')
      expect(config2.public_key).to eq('key2')
    end
  end

  describe 'integration scenarios' do
    context 'development environment setup' do
      it 'configures for local development' do
        config.rest_api_root = 'http://localhost:3000'
        config.upload_api_root = 'http://localhost:3001'
        config.max_request_tries = 3
        config.sign_uploads = false
        config.logger = Logger.new(STDOUT)

        expect(config.rest_api_root).to eq('http://localhost:3000')
        expect(config.upload_api_root).to eq('http://localhost:3001')
        expect(config.max_request_tries).to eq(3)
        expect(config.sign_uploads).to be false
        expect(config.logger).to be_a(Logger)
      end
    end

    context 'production environment setup' do
      it 'configures for production usage' do
        config.public_key = 'pub_production_key'
        config.secret_key = 'secret_production_key'
        config.sign_uploads = true
        config.max_request_tries = 5
        config.max_throttle_attempts = 3
        config.upload_threads = 4

        expect(config.public_key).to eq('pub_production_key')
        expect(config.secret_key).to eq('secret_production_key')
        expect(config.sign_uploads).to be true
        expect(config.max_request_tries).to eq(5)
        expect(config.max_throttle_attempts).to eq(3)
        expect(config.upload_threads).to eq(4)
      end
    end

    context 'high-throughput setup' do
      it 'configures for high-throughput usage' do
        config.upload_threads = 8
        config.multipart_size_threshold = 10 * 1024 * 1024 # 10MB
        config.file_chunk_size = 500
        config.max_throttle_attempts = 10

        expect(config.upload_threads).to eq(8)
        expect(config.multipart_size_threshold).to eq(10 * 1024 * 1024)
        expect(config.file_chunk_size).to eq(500)
        expect(config.max_throttle_attempts).to eq(10)
      end
    end
  end
end
