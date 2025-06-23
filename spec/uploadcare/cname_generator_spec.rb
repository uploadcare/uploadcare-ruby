# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::CnameGenerator do
  before do
    # Reset memoized variables between tests
    described_class.instance_variable_set(:@custom_cname, nil)
    described_class.instance_variable_set(:@custom_cdn_base, nil)
  end

  describe '.generate_cname' do
    it 'delegates to custom_cname' do
      allow(described_class).to receive(:custom_cname).and_return('abc123def')

      result = described_class.generate_cname
      expect(result).to eq('abc123def')
      expect(described_class).to have_received(:custom_cname)
    end
  end

  describe '.custom_cdn_base' do
    before do
      allow(Uploadcare.config).to receive(:custom_cdn_base).and_return('https://ucarecdn.com/')
      allow(described_class).to receive(:generate_cname).and_return('abc123def')
    end

    it 'generates custom CDN base with subdomain' do
      result = described_class.custom_cdn_base
      expect(result).to eq('https://abc123def.ucarecdn.com/')
    end

    it 'handles different CDN bases' do
      allow(Uploadcare.config).to receive(:custom_cdn_base).and_return('https://example.com')
      allow(described_class).to receive(:generate_cname).and_return('xyz789')

      result = described_class.custom_cdn_base
      expect(result).to eq('https://xyz789.example.com')
    end

    it 'memoizes the result' do
      first_call = described_class.custom_cdn_base
      second_call = described_class.custom_cdn_base

      expect(first_call).to eq(second_call)
      expect(described_class).to have_received(:generate_cname).once
    end

    it 'handles CDN base with path' do
      allow(Uploadcare.config).to receive(:custom_cdn_base).and_return('https://cdn.example.com/path/')
      allow(described_class).to receive(:generate_cname).and_return('prefix123')

      result = described_class.custom_cdn_base
      expect(result).to eq('https://prefix123.cdn.example.com/path/')
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

    it 'handles special characters in public key' do
      allow(Uploadcare.config).to receive(:public_key).and_return('key!@#$%^&*()')

      result = described_class.send(:custom_cname)
      expect(result).to be_a(String)
      expect(result.length).to eq(10)
      expect(result).to match(/\A[0-9a-z]{10}\z/)
    end
  end

  describe 'integration tests' do
    context 'with known public key' do
      before do
        allow(Uploadcare.config).to receive(:public_key).and_return('test_key_123')
        allow(Uploadcare.config).to receive(:custom_cdn_base).and_return('https://ucarecdn.com/')
      end

      it 'generates consistent CNAME across method calls' do
        cname1 = described_class.generate_cname
        cname2 = described_class.generate_cname

        expect(cname1).to eq(cname2)
        expect(cname1.length).to eq(10)
      end

      it 'generates valid custom CDN base' do
        cdn_base = described_class.custom_cdn_base

        expect(cdn_base).to start_with('https://')
        expect(cdn_base).to include('.ucarecdn.com/')
        expect(cdn_base).to match(%r{\Ahttps://[0-9a-z]{10}\.ucarecdn\.com/\z})
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
          described_class.instance_variable_set(:@custom_cdn_base, nil)
          allow(Uploadcare.config).to receive(:custom_cdn_base).and_return(cdn_base)
          allow(described_class).to receive(:generate_cname).and_return('test123')

          result = described_class.custom_cdn_base
          expect(result).to include('test123.')
        end
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
