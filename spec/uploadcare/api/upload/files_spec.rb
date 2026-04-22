# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'stringio'

RSpec.describe Uploadcare::Api::Upload::Files do
  subject(:files) { described_class.new(upload: upload_client) }

  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end

  let(:upload_client) { Uploadcare::Api::Upload.new(config: config) }

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

  describe '#direct_many' do
    it 'raises ArgumentError when files is not an array' do
      result = files.direct_many(files: 'not-an-array')

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('files must be an array')
    end

    it 'raises ArgumentError when files is empty' do
      result = files.direct_many(files: [])

      expect(result).to be_failure
      expect(result.error).to be_a(ArgumentError)
      expect(result.error.message).to include('files cannot be empty')
    end

    it 'uses a stable encoded field key when duplicate filenames collide' do
      params = {}
      io_class = Class.new(StringIO) do
        def original_filename
          'photo.jpg'
        end
      end

      io_one = Uploadcare::Internal::UploadIo.wrap(io_class.new('a'))
      io_two = Uploadcare::Internal::UploadIo.wrap(io_class.new('b'))

      begin
        files.send(:form_data_for, io_one, params, field_index: 0)
        files.send(:form_data_for, io_two, params, field_index: 1)
      ensure
        io_one.close!
        io_two.close!
      end

      keys = params.keys
      expect(keys.length).to eq(2)
      expect(keys.first).not_to match(/\A__uploadcare_form_/)
      expect(keys.last).to match(/\A__uploadcare_form_1__/)
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

    it 'preserves explicit false duplicate flags in the request params' do
      stub = stub_request(:post, 'https://upload.uploadcare.com/from_url/')
             .with(
               body: hash_including(
                 'check_URL_duplicates' => 'false',
                 'save_URL_duplicates' => 'false'
               )
             )
             .to_return(
               status: 200,
               body: { token: 'upload-token' }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      files.from_url(
        source_url: source_url,
        async: true,
        check_URL_duplicates: false,
        save_URL_duplicates: false
      )

      expect(stub).to have_been_requested
    end

    it 'computes exponential polling intervals with max cap' do
      expect(files.send(:next_poll_sleep, initial: 1, max_interval: 2, attempt: 0)).to eq(1.0)
      expect(files.send(:next_poll_sleep, initial: 1, max_interval: 2, attempt: 1)).to eq(2.0)
      expect(files.send(:next_poll_sleep, initial: 1, max_interval: 2, attempt: 5)).to eq(2.0)
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

    it 'does not send part_size to multipart/start endpoint' do
      stub = stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
             .with do |request|
               body = URI.decode_www_form(request.body).to_h
               !body.key?('part_size')
             end
             .to_return(
               status: 200,
               body: { uuid: 'mp-uuid', parts: [] }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      files.multipart_start(
        filename: 'test.mp4',
        size: 100_000_000,
        content_type: 'video/mp4',
        part_size: 1024
      )

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
            size: 12_345,
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
