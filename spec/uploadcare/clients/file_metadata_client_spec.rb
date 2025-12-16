# frozen_string_literal: true

require 'spec_helper'

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
      response = client.index(uuid)
      expect(response).to eq(response_body)
    end
  end

  describe '#show' do
    let(:response_body) { 'custom_value' }

    before do
      stub_request(:get, "https://api.uploadcare.com/files/#{uuid}/metadata/#{key}/")
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the value of the specified metadata key' do
      response = client.show(uuid, key)
      expect(response).to eq(response_body)
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
      response = client.update(uuid, key, value)
      expect(response).to eq(response_body)
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.uploadcare.com/files/#{uuid}/metadata/#{key}/")
        .to_return(status: 204, body: '', headers: { 'Content-Type' => 'application/json' })
    end

    it 'deletes the specified metadata key' do
      response = client.delete(uuid, key)
      expect(response).to be_nil
    end
  end
end
