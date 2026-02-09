# frozen_string_literal: true

require 'spec_helper'
require 'uri'

RSpec.describe Uploadcare::FileMetadataClient do
  subject(:client) { described_class.new }

  let(:uuid) { '12345' }
  let(:key) { 'custom_key' }
  let(:value) { 'custom_value' }

  describe '#index' do
    let(:response_body) do
      {
        'custom_key1' => 'custom_value1',
        'custom_key2' => 'custom_value2'
      }
    end

    before do
      stub_request(:get, "https://api.uploadcare.com/files/#{uuid}/metadata/")
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the metadata index for the file' do
      response = client.index(uuid: uuid)
      expect(response.success).to eq(response_body)
    end
  end

  describe '#show' do
    let(:response_body) { 'custom_value' }

    before do
      stub_request(:get, "https://api.uploadcare.com/files/#{uuid}/metadata/#{key}/")
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the value of the specified metadata key' do
      response = client.show(uuid: uuid, key: key)
      expect(response.success).to eq(response_body)
    end
  end

  describe '#update' do
    let(:response_body) { 'custom_value' }

    before do
      stub_request(:put, "https://api.uploadcare.com/files/#{uuid}/metadata/#{key}/")
        .with(body: value.to_json)
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'updates or creates the metadata key with the specified value' do
      response = client.update(uuid: uuid, key: key, value: value)
      expect(response.success).to eq(response_body)
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.uploadcare.com/files/#{uuid}/metadata/#{key}/")
        .to_return(status: 204, body: '', headers: { 'Content-Type' => 'application/json' })
    end

    it 'deletes the specified metadata key' do
      response = client.delete(uuid: uuid, key: key)
      expect(response.success).to be_nil
    end
  end

  describe 'URL encoding' do
    let(:encoded_uuid) { URI.encode_www_form_component(uuid) }
    let(:encoded_key) { URI.encode_www_form_component(key) }

    let(:uuid) { 'file~uuid' }
    let(:key) { 'custom key' }

    before do
      stub_request(:get, "https://api.uploadcare.com/files/#{encoded_uuid}/metadata/#{encoded_key}/")
        .to_return(status: 200, body: value.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'encodes uuid and key in metadata paths' do
      response = client.show(uuid: uuid, key: key)
      expect(response.success).to eq(value)
    end
  end
end
