# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'stringio'

RSpec.describe Uploadcare::Api::Upload::Files do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end

  let(:upload_client) { Uploadcare::Api::Upload.new(config: config) }

  subject(:files) { described_class.new(upload: upload_client) }

  describe '#initialize' do
    it 'stores the upload client' do
      expect(files.upload).to eq(upload_client)
    end
  end

  describe '#direct' do
    let(:tempfile) do
      file = Tempfile.new(['test', '.jpg'])
      file.write('fake image data')
      file.rewind
      file
    end

    after { tempfile.close! }

    it 'uploads a file and returns a Result' do
      stub_request(:post, 'https://upload.uploadcare.com/base/')
        .to_return(
          status: 200,
          body: { 'test.jpg' => 'uploaded-uuid-123' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = files.direct(file: tempfile)

      expect(result).to be_a(Uploadcare::Result)
      expect(result).to be_success
    end

    it 'raises ArgumentError when file does not respond to #read' do
      result = files.direct(file: 'not-a-file')

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('file must be a readable IO object')
    end

    it 'uploads a StringIO by normalizing it to a temp file' do
      io = StringIO.new('fake image data')

      stub_request(:post, 'https://upload.uploadcare.com/base/')
        .to_return(
          status: 200,
          body: { 'upload.bin' => 'uploaded-uuid-123' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = files.direct(file: io)

      expect(result).to be_success
      expect(result.value!).to eq({ 'upload.bin' => 'uploaded-uuid-123' })
    end
  end

  describe '#from_url' do
    let(:source_url) { 'https://example.com/image.jpg' }

    it 'uploads from URL in async mode and returns the token' do
      stub_request(:post, 'https://upload.uploadcare.com/from_url/')
        .to_return(
          status: 200,
          body: { token: 'upload-token-abc' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = files.from_url(source_url: source_url, async: true)

      expect(result).to be_success
      expect(result.value!['token']).to eq('upload-token-abc')
    end

    it 'raises ArgumentError for empty URL' do
      result = files.from_url(source_url: '')

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('URL cannot be empty')
    end

    it 'raises ArgumentError for non-HTTP URL' do
      result = files.from_url(source_url: 'ftp://example.com/file.jpg')

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('URL must be HTTP or HTTPS')
    end

    it 'includes pub_key in the request params' do
      stub = stub_request(:post, 'https://upload.uploadcare.com/from_url/')
        .with(body: hash_including('pub_key' => 'demopublickey', 'source_url' => source_url))
        .to_return(
          status: 200,
          body: { token: 'upload-token' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      files.from_url(source_url: source_url, async: true)

      expect(stub).to have_been_requested
    end
  end

  describe '#from_url_status' do
    it 'returns the upload status for a given token' do
      stub_request(:get, 'https://upload.uploadcare.com/from_url/status/')
        .with(query: hash_including('token' => 'my-token'))
        .to_return(
          status: 200,
          body: { status: 'success', uuid: 'file-uuid', filename: 'image.jpg' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = files.from_url_status(token: 'my-token')

      expect(result).to be_success
      expect(result.value!['status']).to eq('success')
    end

    it 'raises ArgumentError for empty token' do
      result = files.from_url_status(token: '')

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('token cannot be empty')
    end
  end

  describe '#multipart_start' do
    before do
      stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
        .to_return(
          status: 200,
          body: {
            uuid: 'multipart-uuid',
            parts: [
              'https://s3.amazonaws.com/bucket/part1?sig=abc',
              'https://s3.amazonaws.com/bucket/part2?sig=def'
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'starts a multipart upload and returns UUID and presigned URLs' do
      result = files.multipart_start(
        filename: 'large-video.mp4',
        size: 100_000_000,
        content_type: 'video/mp4'
      )

      expect(result).to be_success
      expect(result.value!['uuid']).to eq('multipart-uuid')
      expect(result.value!['parts'].length).to eq(2)
    end

    it 'raises ArgumentError for empty filename' do
      result = files.multipart_start(filename: '', size: 100, content_type: 'video/mp4')

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('filename cannot be empty')
    end

    it 'raises ArgumentError for non-positive size' do
      result = files.multipart_start(filename: 'test.mp4', size: 0, content_type: 'video/mp4')

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('size must be a positive integer')
    end

    it 'raises ArgumentError for empty content_type' do
      result = files.multipart_start(filename: 'test.mp4', size: 100, content_type: '')

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('content_type cannot be empty')
    end

    it 'includes UPLOADCARE_PUB_KEY in the params' do
      stub = stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
        .with(body: hash_including('UPLOADCARE_PUB_KEY' => 'demopublickey'))
        .to_return(
          status: 200,
          body: { uuid: 'mp-uuid', parts: [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      files.multipart_start(filename: 'test.mp4', size: 100_000_000, content_type: 'video/mp4')

      expect(stub).to have_been_requested
    end
  end

  describe '#multipart_complete' do
    before do
      stub_request(:post, 'https://upload.uploadcare.com/multipart/complete/')
        .to_return(
          status: 200,
          body: {
            uuid: 'multipart-uuid',
            filename: 'large-video.mp4',
            size: 100_000_000,
            is_stored: true
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'completes a multipart upload and returns file info' do
      result = files.multipart_complete(uuid: 'multipart-uuid')

      expect(result).to be_success
      expect(result.value!['uuid']).to eq('multipart-uuid')
      expect(result.value!['filename']).to eq('large-video.mp4')
    end

    it 'raises ArgumentError for empty uuid' do
      result = files.multipart_complete(uuid: '')

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('uuid cannot be empty')
    end

    it 'includes UPLOADCARE_PUB_KEY and uuid in the params' do
      stub = stub_request(:post, 'https://upload.uploadcare.com/multipart/complete/')
        .with(body: hash_including('UPLOADCARE_PUB_KEY' => 'demopublickey', 'uuid' => 'mp-uuid'))
        .to_return(
          status: 200,
          body: { uuid: 'mp-uuid' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      files.multipart_complete(uuid: 'mp-uuid')

      expect(stub).to have_been_requested
    end
  end

  describe '#info' do
    before do
      stub_request(:get, 'https://upload.uploadcare.com/info/')
        .with(query: hash_including('pub_key' => 'demopublickey', 'file_id' => 'file-uuid'))
        .to_return(
          status: 200,
          body: {
            uuid: 'file-uuid',
            filename: 'test.jpg',
            size: 12345,
            is_image: true
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns file info from the Upload API' do
      result = files.info(file_id: 'file-uuid')

      expect(result).to be_success
      expect(result.value!['uuid']).to eq('file-uuid')
      expect(result.value!['filename']).to eq('test.jpg')
    end

    it 'raises ArgumentError for empty file_id' do
      result = files.info(file_id: '')

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('file_id cannot be empty')
    end
  end
end
