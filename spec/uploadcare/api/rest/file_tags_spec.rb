# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api::Rest::FileTags do
  subject(:file_tags) { described_class.new(rest: rest) }

  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:rest) { Uploadcare::Api::Rest.new(config: config) }
  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }
  let(:tags_url) { "https://api.uploadcare.com/files/#{file_uuid}/tags/" }

  describe '#list' do
    it 'gets the ordered tag list' do
      stub_request(:get, tags_url)
        .to_return(
          status: 200,
          body: { tags: %w[cat animal] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = file_tags.list(uuid: file_uuid)

      expect(result).to be_success
      expect(result.value!['tags']).to eq(%w[cat animal])
    end

    it 'URI-encodes the UUID in the path' do
      special_uuid = 'uuid/with spaces'
      encoded_uuid = URI.encode_www_form_component(special_uuid)
      stub = stub_request(:get, "https://api.uploadcare.com/files/#{encoded_uuid}/tags/")
             .to_return(
               status: 200,
               body: { tags: [] }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      file_tags.list(uuid: special_uuid)

      expect(stub).to have_been_requested
    end
  end

  describe '#replace' do
    it 'puts the complete replacement list as JSON' do
      stub = stub_request(:put, tags_url)
             .with(body: { tags: %w[cat animal] }.to_json)
             .to_return(
               status: 200,
               body: { tags: %w[cat animal], added: %w[animal cat], deleted: ['old'] }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      result = file_tags.replace(uuid: file_uuid, tags: %w[cat animal])

      expect(result).to be_success
      expect(result.value!['deleted']).to eq(['old'])
      expect(stub).to have_been_requested
    end
  end

  describe '#update' do
    it 'patches additions and deletions atomically as JSON' do
      stub = stub_request(:patch, tags_url)
             .with(body: { add: ['summer'], delete: ['draft'] }.to_json)
             .to_return(
               status: 200,
               body: { tags: ['summer'], added: ['summer'], deleted: ['draft'] }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      result = file_tags.update(uuid: file_uuid, add: ['summer'], delete: ['draft'])

      expect(result).to be_success
      expect(result.value!['added']).to eq(['summer'])
      expect(stub).to have_been_requested
    end

    it 'allows an empty update body' do
      stub = stub_request(:patch, tags_url)
             .with(body: '{}')
             .to_return(
               status: 200,
               body: { tags: [], added: [], deleted: [] }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      result = file_tags.update(uuid: file_uuid)

      expect(result).to be_success
      expect(stub).to have_been_requested
    end
  end
end
