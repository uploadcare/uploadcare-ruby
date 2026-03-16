# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api::Rest::FileMetadata do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end

  let(:rest) { Uploadcare::Api::Rest.new(config: config) }

  subject(:file_metadata) { described_class.new(rest: rest) }

  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

  describe '#initialize' do
    it 'stores the rest client' do
      expect(file_metadata.rest).to eq(rest)
    end
  end

  describe '#index' do
    before do
      stub_request(:get, "https://api.uploadcare.com/files/#{file_uuid}/metadata/")
        .to_return(
          status: 200,
          body: { 'key1' => 'value1', 'key2' => 'value2' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns all metadata for a file' do
      result = file_metadata.index(uuid: file_uuid)

      expect(result).to be_success
      expect(result.value!).to eq({ 'key1' => 'value1', 'key2' => 'value2' })
    end

    it 'URI-encodes the file UUID' do
      uuid_with_special = 'uuid+special'
      encoded_uuid = URI.encode_www_form_component(uuid_with_special)

      stub_request(:get, "https://api.uploadcare.com/files/#{encoded_uuid}/metadata/")
        .to_return(
          status: 200,
          body: {}.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = file_metadata.index(uuid: uuid_with_special)

      expect(result).to be_success
    end

    it 'returns a failure Result when file is not found' do
      stub_request(:get, 'https://api.uploadcare.com/files/nonexistent/metadata/')
        .to_return(
          status: 404,
          body: { detail: 'Not found.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = file_metadata.index(uuid: 'nonexistent')

      expect(result).to be_failure
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.uploadcare.com/files/#{file_uuid}/metadata/my-key/")
        .to_return(
          status: 200,
          body: '"my-value"',
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the value for a specific metadata key' do
      result = file_metadata.show(uuid: file_uuid, key: 'my-key')

      expect(result).to be_success
      expect(result.value!).to eq('my-value')
    end

    it 'URI-encodes both uuid and key' do
      uuid = 'test-uuid'
      key_with_special = 'key with spaces'
      encoded_key = URI.encode_www_form_component(key_with_special)

      stub_request(:get, "https://api.uploadcare.com/files/#{uuid}/metadata/#{encoded_key}/")
        .to_return(
          status: 200,
          body: '"value"',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = file_metadata.show(uuid: uuid, key: key_with_special)

      expect(result).to be_success
    end
  end

  describe '#update' do
    before do
      stub_request(:put, "https://api.uploadcare.com/files/#{file_uuid}/metadata/my-key/")
        .to_return(
          status: 200,
          body: '"new-value"',
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'updates a metadata key and returns the new value' do
      result = file_metadata.update(uuid: file_uuid, key: 'my-key', value: 'new-value')

      expect(result).to be_success
      expect(result.value!).to eq('new-value')
    end

    it 'sends the value as a JSON string in the request body' do
      stub = stub_request(:put, "https://api.uploadcare.com/files/#{file_uuid}/metadata/my-key/")
        .with(body: '"new-value"')
        .to_return(
          status: 200,
          body: '"new-value"',
          headers: { 'Content-Type' => 'application/json' }
        )

      file_metadata.update(uuid: file_uuid, key: 'my-key', value: 'new-value')

      expect(stub).to have_been_requested
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.uploadcare.com/files/#{file_uuid}/metadata/my-key/")
        .to_return(
          status: 200,
          body: ''.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'deletes a metadata key and returns a Result' do
      result = file_metadata.delete(uuid: file_uuid, key: 'my-key')

      expect(result).to be_a(Uploadcare::Result)
      expect(result).to be_success
    end

    it 'URI-encodes both uuid and key' do
      encoded_uuid = URI.encode_www_form_component('test-uuid')
      encoded_key = URI.encode_www_form_component('special/key')

      stub = stub_request(:delete, "https://api.uploadcare.com/files/#{encoded_uuid}/metadata/#{encoded_key}/")
        .to_return(
          status: 200,
          body: ''.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      file_metadata.delete(uuid: 'test-uuid', key: 'special/key')

      expect(stub).to have_been_requested
    end
  end
end
