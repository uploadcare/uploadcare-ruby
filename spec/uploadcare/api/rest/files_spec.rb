# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api::Rest::Files do
  subject(:files) { described_class.new(rest: rest) }

  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

  let(:rest) { Uploadcare::Api::Rest.new(config: config) }

  describe '#initialize' do
    it 'stores the rest client' do
      expect(files.rest).to eq(rest)
    end
  end

  describe '#list' do
    before do
      stub_request(:get, 'https://api.uploadcare.com/files/')
        .to_return(
          status: 200,
          body: {
            next: nil,
            previous: nil,
            total: 2,
            per_page: 100,
            results: [
              { uuid: 'uuid-1', filename: 'file1.jpg' },
              { uuid: 'uuid-2', filename: 'file2.png' }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns a successful Result with paginated file list' do
      result = files.list

      expect(result).to be_success
      expect(result.value!['results'].length).to eq(2)
      expect(result.value!['total']).to eq(2)
    end

    it 'passes query params' do
      stub_request(:get, 'https://api.uploadcare.com/files/')
        .with(query: { limit: '10', ordering: '-datetime_uploaded' })
        .to_return(
          status: 200,
          body: { results: [], total: 0 }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = files.list(params: { limit: '10', ordering: '-datetime_uploaded' })

      expect(result).to be_success
    end
  end

  describe '#info' do
    let(:encoded_uuid) { URI.encode_www_form_component(file_uuid) }

    before do
      stub_request(:get, "https://api.uploadcare.com/files/#{encoded_uuid}/")
        .to_return(
          status: 200,
          body: {
            uuid: file_uuid,
            filename: 'test.jpg',
            size: 12_345,
            is_stored: true,
            is_image: true,
            mime_type: 'image/jpeg'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns file details for the given UUID' do
      result = files.info(uuid: file_uuid)

      expect(result).to be_success
      expect(result.value!['uuid']).to eq(file_uuid)
      expect(result.value!['filename']).to eq('test.jpg')
    end

    it 'accepts additional params like include' do
      stub_request(:get, "https://api.uploadcare.com/files/#{encoded_uuid}/")
        .with(query: { include: 'appdata' })
        .to_return(
          status: 200,
          body: { uuid: file_uuid, appdata: {} }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = files.info(uuid: file_uuid, params: { include: 'appdata' })

      expect(result).to be_success
    end

    it 'returns a failure Result when file is not found' do
      stub_request(:get, 'https://api.uploadcare.com/files/nonexistent/')
        .to_return(
          status: 404,
          body: { detail: 'Not found.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = files.info(uuid: 'nonexistent')

      expect(result).to be_failure
      expect(result.error).to be_a(Uploadcare::Exception::NotFoundError)
    end

    it 'URI-encodes the UUID in the path' do
      special_uuid = 'uuid/with spaces'
      encoded_special_uuid = URI.encode_www_form_component(special_uuid)

      stub = stub_request(:get, "https://api.uploadcare.com/files/#{encoded_special_uuid}/")
             .to_return(
               status: 200,
               body: { uuid: special_uuid }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      files.info(uuid: special_uuid)

      expect(stub).to have_been_requested
    end
  end

  describe '#store' do
    let(:encoded_uuid) { URI.encode_www_form_component(file_uuid) }

    before do
      stub_request(:put, "https://api.uploadcare.com/files/#{encoded_uuid}/storage/")
        .to_return(
          status: 200,
          body: { uuid: file_uuid, is_stored: true }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'stores a file and returns updated file details' do
      result = files.store(uuid: file_uuid)

      expect(result).to be_success
      expect(result.value!['is_stored']).to be true
    end
  end

  describe '#delete' do
    let(:encoded_uuid) { URI.encode_www_form_component(file_uuid) }

    before do
      stub_request(:delete, "https://api.uploadcare.com/files/#{encoded_uuid}/storage/")
        .to_return(
          status: 200,
          body: { uuid: file_uuid }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'deletes a file and returns file details' do
      result = files.delete(uuid: file_uuid)

      expect(result).to be_success
      expect(result.value!['uuid']).to eq(file_uuid)
    end
  end

  describe '#batch_store' do
    let(:uuids) { %w[uuid-1 uuid-2 uuid-3] }

    before do
      stub_request(:put, 'https://api.uploadcare.com/files/storage/')
        .to_return(
          status: 200,
          body: {
            result: [
              { uuid: 'uuid-1' },
              { uuid: 'uuid-2' },
              { uuid: 'uuid-3' }
            ],
            problems: {}
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'batch stores files and returns result with problems' do
      result = files.batch_store(uuids: uuids)

      expect(result).to be_success
      expect(result.value!['result'].length).to eq(3)
      expect(result.value!['problems']).to eq({})
    end
  end

  describe '#batch_delete' do
    let(:uuids) { %w[uuid-1 uuid-2] }

    before do
      stub_request(:delete, 'https://api.uploadcare.com/files/storage/')
        .to_return(
          status: 200,
          body: {
            result: [{ uuid: 'uuid-1' }, { uuid: 'uuid-2' }],
            problems: {}
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'batch deletes files and returns result' do
      result = files.batch_delete(uuids: uuids)

      expect(result).to be_success
      expect(result.value!['result'].length).to eq(2)
    end
  end

  describe '#local_copy' do
    before do
      stub_request(:post, 'https://api.uploadcare.com/files/local_copy/')
        .to_return(
          status: 200,
          body: { type: 'file', result: { uuid: 'new-uuid' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'copies a file to local storage' do
      result = files.local_copy(source: file_uuid)

      expect(result).to be_success
      expect(result.value!['type']).to eq('file')
      expect(result.value!['result']['uuid']).to eq('new-uuid')
    end

    it 'accepts additional options like store' do
      stub_request(:post, 'https://api.uploadcare.com/files/local_copy/')
        .with(body: hash_including('source' => file_uuid, 'store' => true))
        .to_return(
          status: 200,
          body: { type: 'file', result: { uuid: 'new-uuid' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = files.local_copy(source: file_uuid, options: { store: true })

      expect(result).to be_success
    end
  end

  describe '#remote_copy' do
    before do
      stub_request(:post, 'https://api.uploadcare.com/files/remote_copy/')
        .to_return(
          status: 200,
          body: { type: 'url', result: 'https://s3.amazonaws.com/bucket/file.jpg' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'copies a file to remote storage' do
      result = files.remote_copy(source: file_uuid, target: 'my-s3-storage')

      expect(result).to be_success
      expect(result.value!['type']).to eq('url')
    end

    it 'accepts additional options like make_public' do
      stub_request(:post, 'https://api.uploadcare.com/files/remote_copy/')
        .with(body: hash_including('source' => file_uuid, 'target' => 'my-s3', 'make_public' => true))
        .to_return(
          status: 200,
          body: { type: 'url', result: 'https://example.com/file.jpg' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = files.remote_copy(source: file_uuid, target: 'my-s3', options: { make_public: true })

      expect(result).to be_success
    end
  end
end
