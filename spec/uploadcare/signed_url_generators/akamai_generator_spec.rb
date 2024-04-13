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
          expected_url = 'https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=1649343900~acl=/a7d5645e-5cd7-4046-819f-a6a2933bafe3/~hmac=a82d0068adeb2fc5ecf87e7210fe537d234940807725f982dd6c776cbd24df3a'
          expect(subject.generate_url(uuid)).to eq expected_url
        end
      end

      context 'when uuid with transformations' do
        let(:uuid) { "#{super()}/-/resize/640x/other/transformations/" }

        it 'returns correct url' do
          expected_url = 'https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/-/resize/640x/other/transformations/?token=exp=1649343900~acl=/a7d5645e-5cd7-4046-819f-a6a2933bafe3/-/resize/640x/other/transformations/~hmac=7517f479d4413225b48b91f51b83c13f26c1e690adc72dff4dcf627e23d7f676'
          expect(subject.generate_url(uuid)).to eq expected_url
        end
      end

      context 'when acl present' do
        it 'returns correct url' do
          acl = '/*/'
          expected_url = 'https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=1649343900~acl=/*/~hmac=06ab92c7ae863f7d6375d9fd28aa02bd7ca1cab9a10a14653b6cf6ea4f5170b2'
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
          expected_url = 'https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=1649343900~acl=/a7d5645e-5cd7-4046-819f-a6a2933bafe3/*~hmac=f0ae3655fb66376a172c29978c0e3db23c1359aec636c7f3395a165520d84d54'
          expect(subject.generate_url(uuid, nil, wildcard: true)).to eq expected_url
        end
      end
    end
  end
end
