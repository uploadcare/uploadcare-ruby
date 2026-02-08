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

  describe '#custom_cname' do
    it 'generates custom CNAME' do
      allow(Uploadcare::CnameGenerator).to receive(:generate_cname).and_return('custom-cname')

      expect(config.custom_cname).to eq('custom-cname')
    end
  end

  describe '#cdn_base' do
    context 'when use_subdomains is true' do
      before do
        config.use_subdomains = true
        allow(Uploadcare::CnameGenerator).to receive(:cdn_base_postfix).and_return('https://custom.ucarecdn.com/')
      end

      it 'returns subdomain CDN base' do
        expect(config.cdn_base.call).to eq('https://custom.ucarecdn.com/')
      end
    end

    context 'when use_subdomains is false' do
      before do
        config.use_subdomains = false
        config.default_cdn_base = 'https://ucarecdn.com/'
      end

      it 'returns default CDN base' do
        expect(config.cdn_base.call).to eq('https://ucarecdn.com/')
      end
    end
  end

  describe 'initialization with custom options' do
    let(:custom_config) { described_class.new(public_key: 'custom_key', upload_timeout: 120) }

    it 'overrides defaults with provided options' do
      expect(custom_config.public_key).to eq('custom_key')
      expect(custom_config.upload_timeout).to eq(120)
    end

    it 'keeps defaults for non-provided options' do
      expect(custom_config.auth_type).to eq('Uploadcare')
      expect(custom_config.max_request_tries).to eq(100)
    end
  end

  describe 'logger initialization' do
    it 'creates default logger if not provided' do
      expect(config.logger).to be_a(Logger)
    end

    it 'uses provided logger' do
      custom_logger = Logger.new(StringIO.new)
      custom_config = described_class.new(logger: custom_logger)

      expect(custom_config.logger).to eq(custom_logger)
    end
  end
end
