# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Resources::File do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:rest) { instance_double(Uploadcare::Api::Rest) }
  let(:rest_files) { instance_double(Uploadcare::Api::Rest::Files) }
  let(:upload_api) { instance_double(Uploadcare::Api::Upload) }
  let(:upload_files) { double('upload_files') }
  let(:api) { instance_double(Uploadcare::Client::Api, rest: rest, upload: upload_api) }

  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }
  let(:file_attrs) do
    {
      'uuid' => file_uuid,
      'original_filename' => 'photo.jpg',
      'size' => 12_345,
      'mime_type' => 'image/jpeg',
      'is_image' => true,
      'is_ready' => true,
      'url' => "https://ucarecdn.com/#{file_uuid}/",
      'datetime_uploaded' => '2025-01-01T00:00:00Z',
      'datetime_stored' => '2025-01-01T00:00:01Z',
      'datetime_removed' => nil,
      'original_file_url' => "https://ucarecdn.com/#{file_uuid}/photo.jpg",
      'variations' => nil,
      'content_info' => {},
      'metadata' => {},
      'appdata' => nil,
      'source' => nil
    }
  end

  before do
    allow(client).to receive(:api).and_return(api)
    allow(rest).to receive(:files).and_return(rest_files)
  end

  describe 'ATTRIBUTES' do
    it 'defines expected attributes' do
      expected = %i[
        datetime_removed datetime_stored datetime_uploaded is_image is_ready mime_type original_file_url
        original_filename size url uuid variations content_info metadata appdata source
      ]
      expect(described_class::ATTRIBUTES).to match_array(expected)
    end
  end

  describe '#initialize' do
    it 'assigns attributes from a hash' do
      file = described_class.new(file_attrs, client)
      expect(file.uuid).to eq(file_uuid)
      expect(file.original_filename).to eq('photo.jpg')
      expect(file.size).to eq(12_345)
      expect(file.mime_type).to eq('image/jpeg')
      expect(file.is_image).to be true
      expect(file.is_ready).to be true
    end

    it 'stores client reference' do
      file = described_class.new(file_attrs, client)
      expect(file.client).to eq(client)
    end
  end

  describe '.find' do
    it 'fetches file info by UUID' do
      allow(rest_files).to receive(:info)
        .with(uuid: file_uuid, request_options: {})
        .and_return(Uploadcare::Result.success(file_attrs))

      file = described_class.find(uuid: file_uuid, client: client)
      expect(file).to be_a(described_class)
      expect(file.uuid).to eq(file_uuid)
      expect(file.original_filename).to eq('photo.jpg')
    end

    it 'passes params when provided' do
      allow(rest_files).to receive(:info)
        .with(uuid: file_uuid, params: { include: 'appdata' }, request_options: {})
        .and_return(Uploadcare::Result.success(file_attrs))

      file = described_class.find(uuid: file_uuid, params: { include: 'appdata' }, client: client)
      expect(file.uuid).to eq(file_uuid)
    end

    it 'is aliased as retrieve and info' do
      expect(described_class).to respond_to(:retrieve)
      expect(described_class).to respond_to(:info)
    end
  end

  describe '.list' do
    let(:list_response) do
      {
        'results' => [file_attrs],
        'next' => 'https://api.uploadcare.com/files/?limit=10&offset=10',
        'previous' => nil,
        'per_page' => 10,
        'total' => 25
      }
    end

    it 'returns a Paginated collection' do
      allow(rest_files).to receive(:list)
        .with(params: {}, request_options: {})
        .and_return(Uploadcare::Result.success(list_response))

      result = described_class.list(client: client)
      expect(result).to be_a(Uploadcare::Collections::Paginated)
      expect(result.resources.length).to eq(1)
      expect(result.resources.first).to be_a(described_class)
      expect(result.resources.first.uuid).to eq(file_uuid)
      expect(result.total).to eq(25)
      expect(result.per_page).to eq(10)
    end

    it 'passes options as params' do
      allow(rest_files).to receive(:list)
        .with(params: { limit: 5 }, request_options: {})
        .and_return(Uploadcare::Result.success(list_response))

      described_class.list(options: { limit: 5 }, client: client)
    end
  end

  describe '.upload' do
    it 'delegates to upload router' do
      uploads = instance_double(Uploadcare::Operations::UploadRouter)
      allow(client).to receive(:uploads).and_return(uploads)
      file_io = double('file')
      result_file = described_class.new(file_attrs, client)

      allow(uploads).to receive(:upload_file)
        .with(file: file_io, request_options: {}, store: true)
        .and_return(result_file)

      result = described_class.upload(file_io, client: client, store: true)
      expect(result).to eq(result_file)
    end
  end

  describe '.upload_many' do
    it 'delegates to upload router' do
      uploads = instance_double(Uploadcare::Operations::UploadRouter)
      allow(client).to receive(:uploads).and_return(uploads)
      files = [double('file1'), double('file2')]
      result_files = [described_class.new(file_attrs, client)]

      allow(uploads).to receive(:upload_files)
        .with(files: files, request_options: {})
        .and_return(result_files)

      result = described_class.upload_many(files, client: client)
      expect(result).to eq(result_files)
    end
  end

  describe '.upload_url' do
    it 'delegates to upload router' do
      uploads = instance_double(Uploadcare::Operations::UploadRouter)
      allow(client).to receive(:uploads).and_return(uploads)
      result_file = described_class.new(file_attrs, client)

      allow(uploads).to receive(:upload_from_url)
        .with(url: 'https://example.com/img.jpg', request_options: {})
        .and_return(result_file)

      result = described_class.upload_url('https://example.com/img.jpg', client: client)
      expect(result).to eq(result_file)
    end

    it 'is aliased as upload_from_url' do
      expect(described_class).to respond_to(:upload_from_url)
    end
  end

  describe '.batch_store' do
    let(:batch_response) do
      {
        'status' => 'ok',
        'result' => [file_attrs],
        'problems' => {}
      }
    end

    it 'stores files in batch and returns BatchResult' do
      allow(rest_files).to receive(:batch_store)
        .with(uuids: [file_uuid], request_options: {})
        .and_return(Uploadcare::Result.success(batch_response))

      result = described_class.batch_store(uuids: [file_uuid], client: client)
      expect(result).to be_a(Uploadcare::Collections::BatchResult)
      expect(result.status).to eq('ok')
      expect(result.result.length).to eq(1)
      expect(result.result.first).to be_a(described_class)
      expect(result.problems).to eq({})
    end
  end

  describe '.batch_delete' do
    let(:batch_response) do
      {
        'status' => 'ok',
        'result' => [file_attrs],
        'problems' => { 'bad-uuid' => 'Not found' }
      }
    end

    it 'deletes files in batch and returns BatchResult' do
      allow(rest_files).to receive(:batch_delete)
        .with(uuids: [file_uuid, 'bad-uuid'], request_options: {})
        .and_return(Uploadcare::Result.success(batch_response))

      result = described_class.batch_delete(uuids: [file_uuid, 'bad-uuid'], client: client)
      expect(result).to be_a(Uploadcare::Collections::BatchResult)
      expect(result.problems).to eq({ 'bad-uuid' => 'Not found' })
    end
  end

  describe '.local_copy' do
    it 'copies file to local storage' do
      copy_response = { 'result' => file_attrs }
      allow(rest_files).to receive(:local_copy)
        .with(source: file_uuid, options: {}, request_options: {})
        .and_return(Uploadcare::Result.success(copy_response))

      result = described_class.local_copy(source: file_uuid, client: client)
      expect(result).to be_a(described_class)
      expect(result.uuid).to eq(file_uuid)
    end

    it 'is aliased as copy_to_local' do
      expect(described_class).to respond_to(:copy_to_local)
    end
  end

  describe '.remote_copy' do
    it 'copies file to remote storage and returns result URL' do
      remote_url = 's3://bucket/file.jpg'
      copy_response = { 'result' => remote_url }
      allow(rest_files).to receive(:remote_copy)
        .with(source: file_uuid, target: 'my-storage', options: {}, request_options: {})
        .and_return(Uploadcare::Result.success(copy_response))

      result = described_class.remote_copy(source: file_uuid, target: 'my-storage', client: client)
      expect(result).to eq(remote_url)
    end

    it 'is aliased as copy_to_remote' do
      expect(described_class).to respond_to(:copy_to_remote)
    end
  end

  describe '#store' do
    it 'stores the file and updates attributes' do
      file = described_class.new(file_attrs.merge('datetime_stored' => nil), client)
      stored_attrs = file_attrs.merge('datetime_stored' => '2025-06-01T12:00:00Z')

      allow(rest_files).to receive(:store)
        .with(uuid: file_uuid, request_options: {})
        .and_return(Uploadcare::Result.success(stored_attrs))

      result = file.store
      expect(result).to eq(file)
      expect(file.datetime_stored).to eq('2025-06-01T12:00:00Z')
    end
  end

  describe '#delete' do
    it 'deletes the file and updates attributes' do
      file = described_class.new(file_attrs, client)
      deleted_attrs = file_attrs.merge('datetime_removed' => '2025-06-01T12:00:00Z')

      allow(rest_files).to receive(:delete)
        .with(uuid: file_uuid, request_options: {})
        .and_return(Uploadcare::Result.success(deleted_attrs))

      result = file.delete
      expect(result).to eq(file)
      expect(file.datetime_removed).to eq('2025-06-01T12:00:00Z')
    end
  end

  describe '#reload' do
    it 'reloads file info from API' do
      file = described_class.new(file_attrs, client)
      updated_attrs = file_attrs.merge('original_filename' => 'renamed.jpg')

      allow(rest_files).to receive(:info)
        .with(uuid: file_uuid, params: {}, request_options: {})
        .and_return(Uploadcare::Result.success(updated_attrs))

      result = file.reload
      expect(result).to eq(file)
      expect(file.original_filename).to eq('renamed.jpg')
    end

    it 'is aliased as load' do
      file = described_class.new(file_attrs, client)
      expect(file).to respond_to(:load)
    end
  end

  describe '#copy_to_local' do
    it 'copies this file to local storage' do
      file = described_class.new(file_attrs, client)
      copy_response = { 'result' => file_attrs.merge('uuid' => 'new-uuid-copy') }

      allow(rest_files).to receive(:local_copy)
        .with(source: file_uuid, options: {}, request_options: {})
        .and_return(Uploadcare::Result.success(copy_response))

      result = file.copy_to_local
      expect(result).to be_a(described_class)
    end
  end

  describe '#copy_to_remote' do
    it 'copies this file to remote storage' do
      file = described_class.new(file_attrs, client)
      remote_url = 's3://bucket/file.jpg'
      copy_response = { 'result' => remote_url }

      allow(rest_files).to receive(:remote_copy)
        .with(source: file_uuid, target: 'my-storage', options: {}, request_options: {})
        .and_return(Uploadcare::Result.success(copy_response))

      result = file.copy_to_remote(target: 'my-storage')
      expect(result).to eq(remote_url)
    end
  end

  describe '#convert_to_document' do
    let(:rest_doc_conversions) { double('document_conversions') }
    let(:file) { described_class.new(file_attrs, client) }

    before do
      allow(rest).to receive(:document_conversions).and_return(rest_doc_conversions)
    end

    it 'raises ArgumentError when params is not a Hash' do
      expect {
        file.convert_to_document(params: 'not-a-hash')
      }.to raise_error(ArgumentError, 'The first argument must be a Hash')
    end

    it 'converts with document conversion' do
      conversion_response = {
        'result' => [{ 'uuid' => 'converted-uuid' }]
      }
      allow(Uploadcare::Resources::DocumentConversion).to receive(:convert_document)
        .and_return(conversion_response)

      allow(rest_files).to receive(:info)
        .and_return(Uploadcare::Result.success(file_attrs.merge('uuid' => 'converted-uuid')))

      result = file.convert_to_document(params: { format: 'pdf' })
      expect(result).to be_a(described_class)
    end
  end

  describe '#convert_to_video' do
    let(:rest_video_conversions) { double('video_conversions') }
    let(:file) { described_class.new(file_attrs, client) }

    before do
      allow(rest).to receive(:video_conversions).and_return(rest_video_conversions)
    end

    it 'raises ArgumentError when params is not a Hash' do
      expect {
        file.convert_to_video(params: 'not-a-hash')
      }.to raise_error(ArgumentError, 'The first argument must be a Hash')
    end
  end

  describe '#uuid' do
    it 'returns the assigned uuid' do
      file = described_class.new({ 'uuid' => file_uuid }, client)
      expect(file.uuid).to eq(file_uuid)
    end

    it 'extracts uuid from url when uuid not set directly' do
      file = described_class.new({ 'url' => "https://ucarecdn.com/#{file_uuid}/" }, client)
      expect(file.uuid).to eq(file_uuid)
    end

    it 'extracts uuid from original_file_url when url not set' do
      file = described_class.new(
        { 'original_file_url' => "https://ucarecdn.com/#{file_uuid}/photo.jpg" },
        client
      )
      expect(file.uuid).to eq(file_uuid)
    end

    it 'returns nil when no uuid source is available' do
      file = described_class.new({}, client)
      expect(file.uuid).to be_nil
    end
  end

  describe '#cdn_url' do
    it 'returns the url attribute when set' do
      file = described_class.new(file_attrs, client)
      expect(file.cdn_url).to eq("https://ucarecdn.com/#{file_uuid}/")
    end

    it 'builds CDN URL from config and uuid' do
      file = described_class.new({ 'uuid' => file_uuid }, client)
      expect(file.cdn_url).to eq("https://ucarecdn.com/#{file_uuid}/")
    end
  end
end
