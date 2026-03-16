# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api::Upload::Groups do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end

  let(:upload_client) { Uploadcare::Api::Upload.new(config: config) }

  subject(:groups) { described_class.new(upload: upload_client) }

  describe '#initialize' do
    it 'stores the upload client' do
      expect(groups.upload).to eq(upload_client)
    end
  end

  describe '#create' do
    let(:file_uuids) { %w[uuid-1 uuid-2 uuid-3] }

    before do
      stub_request(:post, 'https://upload.uploadcare.com/group/')
        .to_return(
          status: 200,
          body: {
            id: 'group-uuid~3',
            files_count: 3,
            files: [
              { uuid: 'uuid-1' },
              { uuid: 'uuid-2' },
              { uuid: 'uuid-3' }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'creates a group from file UUIDs and returns group info' do
      result = groups.create(files: file_uuids)

      expect(result).to be_success
      expect(result.value!['id']).to eq('group-uuid~3')
      expect(result.value!['files_count']).to eq(3)
    end

    it 'includes pub_key in the request params' do
      stub = stub_request(:post, 'https://upload.uploadcare.com/group/')
             .with(body: hash_including('pub_key' => 'demopublickey'))
             .to_return(
               status: 200,
               body: { id: 'group-uuid~3', files_count: 3 }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      groups.create(files: file_uuids)

      expect(stub).to have_been_requested
    end

    it 'sends each file UUID as files[N] parameter' do
      stub = stub_request(:post, 'https://upload.uploadcare.com/group/')
             .with(body: /files%5B0%5D=uuid-1.*files%5B1%5D=uuid-2.*files%5B2%5D=uuid-3/)
             .to_return(
               status: 200,
               body: { id: 'group-uuid~3', files_count: 3 }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      groups.create(files: file_uuids)

      expect(stub).to have_been_requested
    end

    it 'raises ArgumentError when files is not an array' do
      result = groups.create(files: 'not-an-array')

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('files must be an array')
    end

    it 'raises ArgumentError when files array is empty' do
      result = groups.create(files: [])

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('files cannot be empty')
    end

    it 'accepts objects responding to #uuid' do
      file_obj = double('file', uuid: 'obj-uuid-1')

      stub = stub_request(:post, 'https://upload.uploadcare.com/group/')
             .with(body: /files%5B0%5D=obj-uuid-1/)
             .to_return(
               status: 200,
               body: { id: 'group-uuid~1', files_count: 1 }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      groups.create(files: [file_obj])

      expect(stub).to have_been_requested
    end

    it 'accepts optional signature and expire parameters' do
      stub = stub_request(:post, 'https://upload.uploadcare.com/group/')
             .with(body: hash_including('signature' => 'abc123', 'expire' => '1700000000'))
             .to_return(
               status: 200,
               body: { id: 'group-uuid~1', files_count: 1 }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      groups.create(files: ['uuid-1'], signature: 'abc123', expire: '1700000000')

      expect(stub).to have_been_requested
    end
  end

  describe '#info' do
    let(:group_id) { 'group-uuid~3' }

    before do
      stub_request(:get, 'https://upload.uploadcare.com/group/info/')
        .with(query: hash_including('pub_key' => 'demopublickey', 'group_id' => group_id))
        .to_return(
          status: 200,
          body: {
            id: group_id,
            files_count: 3,
            files: [
              { uuid: 'uuid-1' },
              { uuid: 'uuid-2' },
              { uuid: 'uuid-3' }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns group info from the Upload API' do
      result = groups.info(group_id: group_id)

      expect(result).to be_success
      expect(result.value!['id']).to eq(group_id)
      expect(result.value!['files_count']).to eq(3)
    end

    it 'raises ArgumentError for empty group_id' do
      result = groups.info(group_id: '')

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('group_id cannot be empty')
    end

    it 'includes pub_key in the query params' do
      stub = stub_request(:get, 'https://upload.uploadcare.com/group/info/')
             .with(query: hash_including('pub_key' => 'demopublickey'))
             .to_return(
               status: 200,
               body: { id: group_id }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      groups.info(group_id: group_id)

      expect(stub).to have_been_requested
    end
  end
end
