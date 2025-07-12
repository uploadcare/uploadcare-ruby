# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::CnameGenerator do
  before do
    # Reset memoized variables between tests
    described_class.instance_variable_set(:@custom_cname, nil)
    described_class.instance_variable_set(:@cdn_base_postfix, nil)
  end

  describe '.generate_cname' do
    it 'delegates to custom_cname' do
      allow(described_class).to receive(:custom_cname).and_return('abc123def')

      result = described_class.generate_cname
      expect(result).to eq('abc123def')
      expect(described_class).to have_received(:custom_cname)
    end
  end

  describe '.cdn_base_postfix' do
    before do
      allow(Uploadcare.config).to receive(:cdn_base_postfix).and_return('https://ucarecd.net/')
      allow(described_class).to receive(:generate_cname).and_return('abc123def')
    end

    it 'generates subdomain CDN base with subdomain prefix' do
      result = described_class.cdn_base_postfix
      expect(result).to eq('https://abc123def.ucarecd.net/')
    end

    it 'handles different CDN bases' do
      described_class.instance_variable_set(:@cdn_base_postfix, nil)
      allow(Uploadcare.config).to receive(:cdn_base_postfix).and_return('https://example.com')
      allow(described_class).to receive(:generate_cname).and_return('xyz789')

      result = described_class.cdn_base_postfix
      expect(result).to eq('https://xyz789.example.com')
    end

    it 'memoizes the result' do
      first_call = described_class.cdn_base_postfix
      second_call = described_class.cdn_base_postfix

      expect(first_call).to eq(second_call)
      expect(described_class).to have_received(:generate_cname).once
    end

    it 'handles CDN base with path' do
      described_class.instance_variable_set(:@cdn_base_postfix, nil)
      allow(Uploadcare.config).to receive(:cdn_base_postfix).and_return('https://cdn.example.com/path/')
      allow(described_class).to receive(:generate_cname).and_return('prefix123')

      result = described_class.cdn_base_postfix
      expect(result).to eq('https://prefix123.cdn.example.com/path/')
    end

    it 'raises ConfigurationError for invalid cdn_base URL' do
      # Test with URLs that actually cause URI::InvalidURIError
      invalid_urls = [
        'http://[invalid-host',          # Malformed host with unclosed bracket
        '://missing-scheme',             # Missing protocol scheme
        'https://invalid space.com',     # Invalid characters (spaces) in URL
        'http://[::1',                  # Unclosed IPv6 bracket
        'ftp://host with spaces',       # Spaces in host
        'http://host:abc',              # Invalid port (non-numeric)
        'https://[invalid:bracket'      # Malformed IPv6 bracket
      ]

      invalid_urls.each do |invalid_url|
        # Reset memoization for each test
        described_class.instance_variable_set(:@cdn_base_postfix, nil)
        allow(Uploadcare.config).to receive(:cdn_base_postfix).and_return(invalid_url)
        allow(described_class).to receive(:generate_cname).and_return('test123')

        expect { described_class.cdn_base_postfix }.to raise_error(
          Uploadcare::Exception::ConfigurationError,
          /Invalid cdn_base_postfix URL:/
        )
      end
    end
  end

  describe '.custom_cname' do
    before do
      allow(Uploadcare.config).to receive(:public_key).and_return('test_public_key')
    end

    it 'generates CNAME prefix from public key' do
      result = described_class.send(:custom_cname)

      # Should return a 10-character base36 string
      expect(result).to be_a(String)
      expect(result.length).to eq(10)
      expect(result).to match(/\A[0-9a-z]{10}\z/)
    end

    it 'returns consistent results for same public key' do
      first_result = described_class.send(:custom_cname)
      second_result = described_class.send(:custom_cname)

      expect(first_result).to eq(second_result)
    end

    it 'generates different results for different public keys' do
      allow(Uploadcare.config).to receive(:public_key).and_return('key1')
      result1 = described_class.send(:custom_cname)

      # Reset memoization
      described_class.instance_variable_set(:@custom_cname, nil)

      allow(Uploadcare.config).to receive(:public_key).and_return('key2')
      result2 = described_class.send(:custom_cname)

      expect(result1).not_to eq(result2)
    end

    it 'memoizes the result' do
      allow(Digest::SHA256).to receive(:hexdigest).and_call_original

      described_class.send(:custom_cname)
      described_class.send(:custom_cname)

      # Should only calculate once due to memoization
      expect(Digest::SHA256).to have_received(:hexdigest).once
    end

    it 'handles empty public key' do
      allow(Uploadcare.config).to receive(:public_key).and_return('')

      result = described_class.send(:custom_cname)
      expect(result).to be_a(String)
      expect(result.length).to eq(10)
    end

    it 'handles nil public key' do
      allow(Uploadcare.config).to receive(:public_key).and_return(nil)

      # Should raise ConfigurationError for nil public key
      expect { described_class.send(:custom_cname) }.to raise_error(
        Uploadcare::Exception::ConfigurationError,
        'Invalid public_key: '
      )
    end

    it 'handles special characters in public key' do
      allow(Uploadcare.config).to receive(:public_key).and_return('key!@#$%^&*()')

      result = described_class.send(:custom_cname)
      expect(result).to be_a(String)
      expect(result.length).to eq(10)
      expect(result).to match(/\A[0-9a-z]{10}\z/)
    end

    it 'generates expected CNAME for known public key' do
      # Test with a specific known public key to verify the algorithm
      known_public_key = 'demopublickey'
      allow(Uploadcare.config).to receive(:public_key).and_return(known_public_key)

      # Manual calculation of expected CNAME:
      # 1. SHA256 hash of 'demopublickey'
      sha256_hex = Digest::SHA256.hexdigest(known_public_key)
      # 2. Convert hex to integer
      sha256_int = sha256_hex.to_i(16)
      # 3. Convert to base36
      sha256_base36 = sha256_int.to_s(36)
      # 4. Take first 10 characters
      expected_cname = sha256_base36[0, 10]

      result = described_class.send(:custom_cname)
      expect(result).to eq(expected_cname)

      # For documentation: the expected value for 'demopublickey'
      # SHA256: 4779354e3114e57cb497246520c47b0665144e2f8d45ba518426ecbd407c6cb0
      # Base36: 1s4oyld5dcz61ljfoeb9fbhrbwiefmorovj1mjbaeftkzav7ao
      expect(result).to eq('1s4oyld5dc') # This is the actual computed value
    end
  end

  describe 'integration tests' do
    context 'with known public key' do
      before do
        allow(Uploadcare.config).to receive(:public_key).and_return('test_key_123')
        allow(Uploadcare.config).to receive(:cdn_base_postfix).and_return('https://ucarecd.net/')
      end

      it 'generates consistent CNAME across method calls' do
        cname1 = described_class.generate_cname
        cname2 = described_class.generate_cname

        expect(cname1).to eq(cname2)
        expect(cname1.length).to eq(10)
      end

      it 'generates valid subdomain CDN base' do
        cdn_base = described_class.cdn_base_postfix

        expect(cdn_base).to start_with('https://')
        expect(cdn_base).to include('.ucarecd.net/')
        expect(cdn_base).to match(%r{\Ahttps://[0-9a-z]{10}\.ucarecd\.net/\z})
      end
    end

    context 'with different configurations' do
      it 'adapts to different CDN bases' do
        test_cases = [
          'https://cdn.example.com',
          'https://my-cdn.net/',
          'https://custom.domain.org/path'
        ]

        test_cases.each do |cdn_base|
          described_class.instance_variable_set(:@cdn_base_postfix, nil)
          allow(Uploadcare.config).to receive(:cdn_base_postfix).and_return(cdn_base)
          allow(described_class).to receive(:generate_cname).and_return('test123')

          result = described_class.cdn_base_postfix
          expect(result).to include('test123.')
        end
      end
    end

    context 'manual CNAME generation verification' do
      it 'generates expected CNAME and CDN base for real-world scenario' do
        # Real-world test with a specific public key
        test_public_key = 'pub_12345test'
        allow(Uploadcare.config).to receive(:public_key).and_return(test_public_key)
        allow(Uploadcare.config).to receive(:cdn_base_postfix).and_return('https://ucarecd.net/')

        # Calculate expected CNAME manually
        sha256_hex = Digest::SHA256.hexdigest(test_public_key)
        sha256_int = sha256_hex.to_i(16)
        expected_cname = sha256_int.to_s(36)[0, 10]

        # Test CNAME generation
        generated_cname = described_class.generate_cname
        expect(generated_cname).to eq(expected_cname)

        # Test full CDN base generation
        expected_cdn_base = "https://#{expected_cname}.ucarecd.net/"
        generated_cdn_base = described_class.cdn_base_postfix
        expect(generated_cdn_base).to eq(expected_cdn_base)
      end
    end
  end

  describe 'constants' do
    it 'defines CNAME_PREFIX_LEN' do
      expect(described_class::CNAME_PREFIX_LEN).to eq(10)
    end
  end

  describe 'performance' do
    it 'memoizes expensive operations' do
      allow(Digest::SHA256).to receive(:hexdigest).and_call_original

      # First call
      described_class.send(:custom_cname)

      # Second call should use memoized value
      described_class.send(:custom_cname)

      expect(Digest::SHA256).to have_received(:hexdigest).once
    end
  end
end
