# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::SignedUrlGenerators::BaseGenerator do
  let(:cdn_host) { 'cdn.example.com' }
  let(:secret_key) { 'test-secret-key' }
  let(:generator) { described_class.new(cdn_host: cdn_host, secret_key: secret_key) }

  describe '#initialize' do
    it 'sets cdn_host' do
      expect(generator.cdn_host).to eq(cdn_host)
    end

    it 'sets secret_key' do
      expect(generator.secret_key).to eq(secret_key)
    end
  end

  describe '#generate_url' do
    it 'raises NotImplementedError' do
      expect { generator.generate_url('uuid') }.to raise_error(
        NotImplementedError,
        'Subclasses must implement generate_url method'
      )
    end

    it 'raises NotImplementedError with expiration parameter' do
      expect { generator.generate_url('uuid', 1234567890) }.to raise_error(
        NotImplementedError,
        'Subclasses must implement generate_url method'
      )
    end
  end

  describe '#build_url' do
    it 'builds HTTPS URL with path' do
      url = generator.send(:build_url, '/path/to/resource')
      expect(url).to eq('https://cdn.example.com/path/to/resource')
    end

    it 'builds URL with query parameters' do
      url = generator.send(:build_url, '/path', { token: 'abc123', exp: '1234567890' })
      
      uri = URI.parse(url)
      expect(uri.scheme).to eq('https')
      expect(uri.host).to eq('cdn.example.com')
      expect(uri.path).to eq('/path')
      
      params = URI.decode_www_form(uri.query).to_h
      expect(params).to eq({
        'token' => 'abc123',
        'exp' => '1234567890'
      })
    end

    it 'handles empty query parameters' do
      url = generator.send(:build_url, '/path', {})
      expect(url).to eq('https://cdn.example.com/path')
      expect(url).not_to include('?')
    end

    it 'properly encodes query parameters' do
      url = generator.send(:build_url, '/path', { 
        'special chars' => 'value with spaces',
        'symbols' => '!@#$%'
      })
      
      uri = URI.parse(url)
      params = URI.decode_www_form(uri.query).to_h
      
      expect(params['special chars']).to eq('value with spaces')
      expect(params['symbols']).to eq('!@#$%')
    end

    it 'handles paths with leading slash' do
      url = generator.send(:build_url, '/leading/slash')
      expect(url).to eq('https://cdn.example.com/leading/slash')
    end

    it 'handles paths without leading slash' do
      url = generator.send(:build_url, 'no/leading/slash')
      expect(url).to eq('https://cdn.example.com/no/leading/slash')
    end
  end

  describe 'inheritance' do
    let(:custom_generator_class) do
      Class.new(described_class) do
        def generate_url(uuid, expiration = nil)
          expiration ||= Time.now.to_i + 300
          build_url("/#{uuid}/", { token: "test-#{expiration}" })
        end
      end
    end

    let(:custom_generator) { custom_generator_class.new(cdn_host: cdn_host, secret_key: secret_key) }

    it 'allows subclasses to implement generate_url' do
      url = custom_generator.generate_url('test-uuid')
      
      expect(url).to start_with('https://cdn.example.com/test-uuid/')
      expect(url).to include('token=test-')
    end

    it 'inherits initialization' do
      expect(custom_generator.cdn_host).to eq(cdn_host)
      expect(custom_generator.secret_key).to eq(secret_key)
    end

    it 'can use build_url from parent' do
      allow(Time).to receive(:now).and_return(Time.at(1609459200))
      
      url = custom_generator.generate_url('uuid', 1609459500)
      expect(url).to eq('https://cdn.example.com/uuid/?token=test-1609459500')
    end
  end

  describe 'with different CDN hosts' do
    it 'handles hosts with subdomains' do
      generator = described_class.new(
        cdn_host: 'static.cdn.example.com',
        secret_key: 'key'
      )
      
      url = generator.send(:build_url, '/path')
      expect(url).to eq('https://static.cdn.example.com/path')
    end

    it 'handles hosts with ports' do
      generator = described_class.new(
        cdn_host: 'cdn.example.com:8443',
        secret_key: 'key'
      )
      
      url = generator.send(:build_url, '/path')
      expect(url).to eq('https://cdn.example.com:8443/path')
    end

    it 'handles IP addresses' do
      generator = described_class.new(
        cdn_host: '192.168.1.1',
        secret_key: 'key'
      )
      
      url = generator.send(:build_url, '/path')
      expect(url).to eq('https://192.168.1.1/path')
    end
  end
end