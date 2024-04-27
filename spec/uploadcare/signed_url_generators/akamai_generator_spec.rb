# frozen_string_literal: true

require 'spec_helper'
require 'signed_url_generators/akamai_generator'

module Uploadcare
  RSpec.describe SignedUrlGenerators::AkamaiGenerator do
    subject { described_class.new(cdn_host: 'example.com', secret_key: secret_key) }

    let(:default_ttl) { 300 }
    let(:default_algorithm) { 'sha256' }
    let(:uuid) { 'a7d5645e-5cd7-4046-819f-a6a2933bafe3' }
    let(:unixtime) { '1649343600' }
    let(:secret_key) { 'secret_key' }

    describe '#generate_url' do
      before do
        allow(Time).to receive(:now).and_return(unixtime)
      end

      context 'when acl not present' do
        it 'returns correct url' do
          expected_url = 'https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=1649343900~acl=/a7d5645e-5cd7-4046-819f-a6a2933bafe3/~hmac=d8b4919d595805fd8923258bb647065b7d7201dad8f475d6f5c430e3bffa8122'
          expect(subject.generate_url(uuid)).to eq expected_url
        end
      end

      context 'when uuid with transformations' do
        let(:uuid) { "#{super()}/-/resize/640x/other/transformations/" }

        it 'returns correct url' do
          expected_url = 'https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/-/resize/640x/other/transformations/?token=exp=1649343900~acl=/a7d5645e-5cd7-4046-819f-a6a2933bafe3/-/resize/640x/other/transformations/~hmac=64dd1754c71bf194fcc81d49c413afeb3bbe0e6d703ed4c9b30a8a48c1782f53'
          expect(subject.generate_url(uuid)).to eq expected_url
        end
      end

      context 'when acl present' do
        it 'returns correct url' do
          acl = '/*/'
          expected_url = 'https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=1649343900~acl=/*/~hmac=984914950bccbfe22f542aa1891300fb2624def1208452335fc72520c934c4c3'
          expect(subject.generate_url(uuid, acl)).to eq expected_url
        end
      end

      context 'when uuid not valid' do
        it 'returns exception' do
          expect { subject.generate_url(SecureRandom.hex) }.to raise_error ArgumentError
        end
      end

      context 'when wildcard is true' do
        it 'returns correct url' do
          expected_url = 'https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=1649343900~acl=/a7d5645e-5cd7-4046-819f-a6a2933bafe3/*~hmac=6f032220422cdaea5fe0b58f9dcf681269591bb5d1231aa1c4a38741d7cc2fe5'
          expect(subject.generate_url(uuid, nil, wildcard: true)).to eq expected_url
        end
      end
    end
  end
end
