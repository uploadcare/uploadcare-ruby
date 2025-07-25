# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::SignedUrlGenerators::AkamaiGenerator do
  let(:cdn_host) { 'cdn.example.com' }
  let(:secret_key) { '0123456789abcdef0123456789abcdef' }
  let(:generator) { described_class.new(cdn_host: cdn_host, secret_key: secret_key) }

  describe '#generate_url' do
    let(:uuid) { '12345678-1234-1234-1234-123456789012' }

    context 'with default expiration' do
      before do
        # Freeze time for predictable results
        allow(Time).to receive(:now).and_return(Time.at(1_609_459_200)) # 2021-01-01 00:00:00 UTC
      end

      it 'generates a signed URL with 5 minute expiration' do
        url = generator.generate_url(uuid)

        expect(url).to start_with("https://#{cdn_host}/#{uuid}/")
        expect(url).to include('token=')
        expect(url).to include('exp=1609459500') # 5 minutes later
        expect(url).to include("acl=/#{uuid}/")
        expect(url).to include('hmac=')
      end

      it 'generates different URLs for different UUIDs' do
        url1 = generator.generate_url('uuid-1')
        url2 = generator.generate_url('uuid-2')

        expect(url1).not_to eq(url2)
      end
    end

    context 'with custom expiration' do
      it 'uses provided expiration time' do
        custom_expiration = 1_609_462_800 # 2021-01-01 01:00:00 UTC
        url = generator.generate_url(uuid, custom_expiration)

        expect(url).to include("exp=#{custom_expiration}")
      end
    end

    context 'with different secret keys' do
      it 'generates different signatures' do
        generator1 = described_class.new(cdn_host: cdn_host, secret_key: '1111111111111111')
        generator2 = described_class.new(cdn_host: cdn_host, secret_key: '2222222222222222')

        # Use same time for both
        time = Time.at(1_609_459_200)
        allow(Time).to receive(:now).and_return(time)

        url1 = generator1.generate_url(uuid)
        url2 = generator2.generate_url(uuid)

        # Extract HMAC from URLs
        hmac1 = url1.match(/hmac=([^&]+)/)[1]
        hmac2 = url2.match(/hmac=([^&]+)/)[1]

        expect(hmac1).not_to eq(hmac2)
      end
    end

    describe 'token format' do
      before do
        allow(Time).to receive(:now).and_return(Time.at(1_609_459_200))
      end

      it 'includes all required token components' do
        url = generator.generate_url(uuid)
        token_match = url.match(/token=(.+)$/)
        expect(token_match).not_to be_nil

        token = token_match[1]
        expect(token).to match(/^exp=\d+~acl=.+~hmac=.+$/)
      end

      it 'uses URL-safe base64 encoding for HMAC' do
        url = generator.generate_url(uuid)
        hmac = url.match(/hmac=([^&]+)/)[1]

        # URL-safe base64 should not contain +, /, or =
        expect(hmac).not_to include('+')
        expect(hmac).not_to include('/')
        expect(hmac).not_to include('=')
      end
    end

    describe 'ACL path' do
      it 'includes trailing slash in ACL' do
        url = generator.generate_url(uuid)
        expect(url).to include("acl=/#{uuid}/")
      end

      it 'uses UUID as path component' do
        special_uuid = 'test-uuid-with-special-chars'
        url = generator.generate_url(special_uuid)
        expect(url).to include("acl=/#{special_uuid}/")
      end
    end
  end

  describe '#generate_token' do
    it 'creates HMAC-SHA256 signature' do
      acl = '/test-uuid/'
      expiration = 1_609_459_200

      token = generator.send(:generate_token, acl, expiration)

      expect(token).to be_a(String)
      expect(token).not_to be_empty
    end

    it 'generates consistent tokens for same inputs' do
      acl = '/test-uuid/'
      expiration = 1_609_459_200

      token1 = generator.send(:generate_token, acl, expiration)
      token2 = generator.send(:generate_token, acl, expiration)

      expect(token1).to eq(token2)
    end
  end

  describe '#hex_to_binary' do
    it 'converts hex string to binary' do
      hex = '48656c6c6f' # "Hello" in hex
      binary = generator.send(:hex_to_binary, hex)

      expect(binary).to eq('Hello')
    end

    it 'handles lowercase hex' do
      hex = 'abcdef'
      binary = generator.send(:hex_to_binary, hex)

      expect(binary.bytes).to eq([171, 205, 239])
    end

    it 'handles uppercase hex' do
      hex = 'ABCDEF'
      binary = generator.send(:hex_to_binary, hex)

      expect(binary.bytes).to eq([171, 205, 239])
    end
  end

  describe 'integration' do
    it 'generates valid URL structure' do
      allow(Time).to receive(:now).and_return(Time.at(1_609_459_200))

      url = generator.generate_url('test-file-uuid')
      uri = URI.parse(url)

      expect(uri.scheme).to eq('https')
      expect(uri.host).to eq(cdn_host)
      expect(uri.path).to eq('/test-file-uuid/')
      expect(uri.query).to match(/^token=exp=\d+~acl=.+~hmac=.+$/)
    end

    it 'generates URLs that expire at the correct time' do
      current_time = Time.at(1_609_459_200)
      allow(Time).to receive(:now).and_return(current_time)

      url = generator.generate_url('uuid')

      # Extract expiration from URL
      exp_match = url.match(/exp=(\d+)/)
      expect(exp_match).not_to be_nil

      expiration = Time.at(exp_match[1].to_i)
      expect(expiration).to eq(current_time + 300) # 5 minutes
    end
  end
end
