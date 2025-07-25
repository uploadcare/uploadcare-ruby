# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::CnameGenerator do
  describe '.generate' do
    it 'generates consistent subdomain from public key' do
      subdomain = described_class.generate('demopublickey')
      expect(subdomain).to eq('0fed487a8a')
      expect(subdomain.length).to eq(10)
    end

    it 'returns same subdomain for same key' do
      key = 'test_public_key'
      subdomain1 = described_class.generate(key)
      subdomain2 = described_class.generate(key)
      
      expect(subdomain1).to eq(subdomain2)
    end

    it 'returns different subdomains for different keys' do
      subdomain1 = described_class.generate('key1')
      subdomain2 = described_class.generate('key2')
      
      expect(subdomain1).not_to eq(subdomain2)
    end

    it 'returns nil for nil public key' do
      expect(described_class.generate(nil)).to be_nil
    end

    it 'returns nil for empty public key' do
      expect(described_class.generate('')).to be_nil
    end
  end

  describe '.cdn_base_url' do
    let(:public_key) { 'demopublickey' }
    let(:cdn_base_postfix) { 'https://ucarecd.net/' }

    it 'generates subdomain-based CDN URL' do
      url = described_class.cdn_base_url(public_key, cdn_base_postfix)
      expect(url).to eq('https://0fed487a8a.ucarecd.net/')
    end

    it 'preserves path in CDN base postfix' do
      cdn_base = 'https://cdn.example.com/path/'
      url = described_class.cdn_base_url(public_key, cdn_base)
      expect(url).to match(%r{https://[a-z0-9]+\.cdn\.example\.com/path/})
    end

    it 'returns original CDN base when public key is nil' do
      url = described_class.cdn_base_url(nil, cdn_base_postfix)
      expect(url).to eq(cdn_base_postfix)
    end

    it 'returns original CDN base when public key is empty' do
      url = described_class.cdn_base_url('', cdn_base_postfix)
      expect(url).to eq(cdn_base_postfix)
    end

    it 'handles CDN base without trailing slash' do
      cdn_base = 'https://ucarecd.net'
      url = described_class.cdn_base_url(public_key, cdn_base)
      expect(url).to eq('https://0fed487a8a.ucarecd.net')
    end
  end
end