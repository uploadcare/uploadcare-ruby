# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Internal::UserAgent do
  describe '.call' do
    let(:config) do
      Uploadcare::Configuration.new(
        public_key: 'my-pub-key',
        secret_key: 'my-secret-key',
        framework_data: framework_data
      )
    end

    context 'without framework_data' do
      let(:framework_data) { '' }

      it 'returns a properly formatted user agent string' do
        result = described_class.call(config: config)
        expect(result).to eq(
          "UploadcareRuby/#{Uploadcare::VERSION}/my-pub-key (Ruby/#{RUBY_VERSION})"
        )
      end
    end

    context 'with framework_data' do
      let(:framework_data) { 'Rails/7.1.0' }

      it 'appends framework data in parentheses' do
        result = described_class.call(config: config)
        expect(result).to eq(
          "UploadcareRuby/#{Uploadcare::VERSION}/my-pub-key (Ruby/#{RUBY_VERSION}; Rails/7.1.0)"
        )
      end
    end

    context 'with nil framework_data' do
      let(:framework_data) { nil }

      it 'omits framework data' do
        result = described_class.call(config: config)
        expect(result).to eq(
          "UploadcareRuby/#{Uploadcare::VERSION}/my-pub-key (Ruby/#{RUBY_VERSION})"
        )
      end
    end

    it 'includes the gem version' do
      config = Uploadcare::Configuration.new(public_key: 'pk', secret_key: 'sk')
      result = described_class.call(config: config)
      expect(result).to include(Uploadcare::VERSION)
    end

    it 'includes the public key' do
      config = Uploadcare::Configuration.new(public_key: 'unique-key-123', secret_key: 'sk')
      result = described_class.call(config: config)
      expect(result).to include('unique-key-123')
    end

    it 'includes the Ruby version' do
      config = Uploadcare::Configuration.new(public_key: 'pk', secret_key: 'sk')
      result = described_class.call(config: config)
      expect(result).to include("Ruby/#{RUBY_VERSION}")
    end
  end
end
