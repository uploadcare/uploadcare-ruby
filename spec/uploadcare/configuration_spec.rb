# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Configuration do
  describe 'DEFAULTS' do
    it 'defines all expected default values' do
      defaults = described_class::DEFAULTS

      expect(defaults[:public_key]).to be_nil
      expect(defaults[:secret_key]).to be_nil
      expect(defaults[:auth_type]).to eq('Uploadcare')
      expect(defaults[:multipart_size_threshold]).to eq(100 * 1024 * 1024)
      expect(defaults[:rest_api_root]).to eq('https://api.uploadcare.com')
      expect(defaults[:upload_api_root]).to eq('https://upload.uploadcare.com')
      expect(defaults[:max_request_tries]).to eq(100)
      expect(defaults[:base_request_sleep]).to eq(1)
      expect(defaults[:max_request_sleep]).to eq(60.0)
      expect(defaults[:sign_uploads]).to be false
      expect(defaults[:upload_signature_lifetime]).to eq(30 * 60)
      expect(defaults[:max_throttle_attempts]).to eq(5)
      expect(defaults[:upload_threads]).to eq(2)
      expect(defaults[:framework_data]).to eq('')
      expect(defaults[:file_chunk_size]).to eq(100)
      expect(defaults[:logger]).to be_nil
      expect(defaults[:use_subdomains]).to be false
      expect(defaults[:cdn_base_postfix]).to eq('https://ucarecd.net/')
      expect(defaults[:default_cdn_base]).to eq('https://ucarecdn.com/')
      expect(defaults[:multipart_chunk_size]).to eq(5 * 1024 * 1024)
      expect(defaults[:upload_timeout]).to eq(60)
      expect(defaults[:max_upload_retries]).to eq(3)
    end

    it 'is frozen' do
      expect(described_class::DEFAULTS).to be_frozen
    end
  end

  describe '#initialize' do
    it 'uses defaults when no options given' do
      config = described_class.new
      expect(config.auth_type).to eq('Uploadcare')
      expect(config.multipart_size_threshold).to eq(100 * 1024 * 1024)
      expect(config.rest_api_root).to eq('https://api.uploadcare.com')
    end

    it 'overrides defaults with provided options' do
      config = described_class.new(
        public_key: 'my-key',
        secret_key: 'my-secret',
        auth_type: 'Uploadcare.Simple'
      )
      expect(config.public_key).to eq('my-key')
      expect(config.secret_key).to eq('my-secret')
      expect(config.auth_type).to eq('Uploadcare.Simple')
    end

    it 'falls back to ENV for public_key when nil' do
      original_env = ENV.fetch('UPLOADCARE_PUBLIC_KEY', nil)
      ENV['UPLOADCARE_PUBLIC_KEY'] = 'env-public-key'

      config = described_class.new
      expect(config.public_key).to eq('env-public-key')

      if original_env
        ENV['UPLOADCARE_PUBLIC_KEY'] = original_env
      else
        ENV.delete('UPLOADCARE_PUBLIC_KEY')
      end
    end

    it 'falls back to ENV for secret_key when nil' do
      original_env = ENV.fetch('UPLOADCARE_SECRET_KEY', nil)
      ENV['UPLOADCARE_SECRET_KEY'] = 'env-secret-key'

      config = described_class.new
      expect(config.secret_key).to eq('env-secret-key')

      if original_env
        ENV['UPLOADCARE_SECRET_KEY'] = original_env
      else
        ENV.delete('UPLOADCARE_SECRET_KEY')
      end
    end

    it 'creates a logger by default' do
      config = described_class.new
      expect(config.logger).to be_a(Logger)
    end

    it 'uses a provided logger' do
      custom_logger = Logger.new($stderr)
      config = described_class.new(logger: custom_logger)
      expect(config.logger).to eq(custom_logger)
    end
  end

  describe '#with' do
    it 'creates a new configuration with overrides' do
      config = described_class.new(public_key: 'original', secret_key: 'secret')
      new_config = config.with(public_key: 'overridden')

      expect(new_config.public_key).to eq('overridden')
      expect(new_config.secret_key).to eq('secret')
    end

    it 'does not mutate the original config' do
      config = described_class.new(public_key: 'original')
      config.with(public_key: 'changed')

      expect(config.public_key).to eq('original')
    end

    it 'returns a new Configuration instance' do
      config = described_class.new
      new_config = config.with(auth_type: 'Uploadcare.Simple')

      expect(new_config).to be_a(described_class)
      expect(new_config).not_to equal(config)
    end
  end

  describe '#to_h' do
    it 'returns a hash of all configuration values' do
      config = described_class.new(
        public_key: 'pk',
        secret_key: 'sk',
        auth_type: 'Uploadcare.Simple'
      )
      hash = config.to_h

      expect(hash).to be_a(Hash)
      expect(hash[:public_key]).to eq('pk')
      expect(hash[:secret_key]).to eq('sk')
      expect(hash[:auth_type]).to eq('Uploadcare.Simple')
      expect(hash[:rest_api_root]).to eq('https://api.uploadcare.com')
    end

    it 'includes all DEFAULTS keys' do
      config = described_class.new
      hash = config.to_h

      described_class::DEFAULTS.each_key do |key|
        expect(hash).to have_key(key)
      end
    end
  end

  describe '#cdn_base' do
    it 'returns default_cdn_base when use_subdomains is false' do
      config = described_class.new(
        public_key: 'pk',
        use_subdomains: false,
        default_cdn_base: 'https://ucarecdn.com/'
      )
      expect(config.cdn_base).to eq('https://ucarecdn.com/')
    end

    it 'generates subdomain-based CDN base when use_subdomains is true' do
      config = described_class.new(
        public_key: 'pk',
        use_subdomains: true,
        cdn_base_postfix: 'https://ucarecd.net/'
      )
      cdn = config.cdn_base
      expect(cdn).to include('ucarecd.net')
      expect(cdn).to start_with('https://')
    end
  end

  describe '#custom_cname' do
    it 'generates a CNAME from the public key' do
      config = described_class.new(public_key: 'demopublickey')
      cname = config.custom_cname
      expect(cname).to be_a(String)
      expect(cname.length).to eq(10)
    end

    it 'generates consistent cnames for the same key' do
      config = described_class.new(public_key: 'test-key')
      expect(config.custom_cname).to eq(config.custom_cname)
    end

    it 'generates different cnames for different keys' do
      config1 = described_class.new(public_key: 'key-alpha')
      config2 = described_class.new(public_key: 'key-beta')
      expect(config1.custom_cname).not_to eq(config2.custom_cname)
    end
  end

  describe 'attr_accessors' do
    it 'allows setting and getting all configuration attributes' do
      config = described_class.new

      config.public_key = 'new-pk'
      expect(config.public_key).to eq('new-pk')

      config.max_request_tries = 50
      expect(config.max_request_tries).to eq(50)

      config.sign_uploads = true
      expect(config.sign_uploads).to be true
    end
  end
end
