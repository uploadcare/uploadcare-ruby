# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe UploadClient do
    let(:config) { Uploadcare.configuration }
    let(:client) { described_class.new(config: config) }
    let(:file_path) { 'spec/fixtures/kitten.jpeg' }
    let(:file) { ::File.open(file_path, 'rb') }

    after { file.close if file && !file.closed? }

    describe '#initialize' do
      it 'creates a client with upload API root' do
        expect(client).to be_a(described_class)
      end

      it 'uses the configured upload_api_root' do
        expect(config.upload_api_root).to eq('https://upload.uploadcare.com')
      end
    end

    describe '#upload_file' do
      let(:upload_response) do
        {
          'file' => 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          'original_filename' => 'kitten.jpeg',
          'size' => 12_345,
          'mime_type' => 'image/jpeg'
        }
      end

      before do
        stub_request(:post, 'https://upload.uploadcare.com/base/')
          .to_return(status: 200, body: upload_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      context 'with valid file' do
        it 'uploads a file successfully' do
          result = client.upload_file(file: file)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success).to have_key('file')
          expect(result.success['file']).to match(/^[a-f0-9-]{36}$/)
        end

        it 'uploads with store option' do
          result = client.upload_file(file: file, store: true)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success).to have_key('file')
        end

        it 'uploads with metadata' do
          metadata = { 'tag' => 'test', 'source' => 'rspec' }
          result = client.upload_file(file: file, metadata: metadata)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success).to have_key('file')
        end
      end

      context 'with invalid input' do
        it 'raises ArgumentError for non-file object' do
          result = client.upload_file(file: 'not a file')
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/file must be a File or IO object/)
        end

        it 'raises ArgumentError for nil' do
          result = client.upload_file(file: nil)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
        end
      end
    end

    describe '#upload_from_url' do
      let(:source_url) { 'https://example.com/image.jpg' }
      let(:async_response) do
        {
          'type' => 'token',
          'token' => 'token-uuid-1234'
        }
      end
      let(:status_response) do
        {
          'status' => 'success',
          'uuid' => 'file-uuid-5678',
          'original_filename' => 'image.jpg',
          'size' => 54_321
        }
      end

      context 'when async mode is enabled' do
        before do
          stub_request(:post, 'https://upload.uploadcare.com/from_url/')
            .to_return(status: 200, body: async_response.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'returns token immediately' do
          result = client.upload_from_url(source_url: source_url, async: true)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success).to have_key('token')
          expect(result.success['type']).to eq('token')
        end

        it 'uploads with store option' do
          result = client.upload_from_url(source_url: source_url, async: true, store: true)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success).to have_key('token')
        end

        it 'uploads with metadata' do
          metadata = { 'source' => 'web' }
          result = client.upload_from_url(source_url: source_url, async: true, metadata: metadata)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success).to have_key('token')
        end
      end

      context 'when polling synchronously' do
        before do
          stub_request(:post, 'https://upload.uploadcare.com/from_url/')
            .to_return(status: 200, body: async_response.to_json, headers: { 'Content-Type' => 'application/json' })

          stub_request(:get, %r{https://upload\.uploadcare\.com/from_url/status/})
            .to_return(status: 200, body: status_response.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'polls and returns file info' do
          result = client.upload_from_url(source_url: source_url)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success).to have_key('uuid')
          expect(result.success['status']).to eq('success')
        end

        it 'polls with custom interval' do
          result = client.upload_from_url(source_url: source_url, poll_interval: 0.1)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success).to have_key('uuid')
        end
      end

      context 'with invalid URL' do
        it 'raises ArgumentError for empty URL' do
          result = client.upload_from_url(source_url: '')
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/URL cannot be empty/)
        end

        it 'raises ArgumentError for nil URL' do
          result = client.upload_from_url(source_url: nil)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/URL cannot be empty/)
        end

        it 'raises ArgumentError for invalid URL format' do
          result = client.upload_from_url(source_url: 'not a url')
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/Invalid URL/)
        end

        it 'raises ArgumentError for non-HTTP URL' do
          result = client.upload_from_url(source_url: 'ftp://example.com/file.jpg')
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/must be HTTP or HTTPS/)
        end
      end

      context 'with upload error' do
        before do
          stub_request(:post, 'https://upload.uploadcare.com/from_url/')
            .to_return(status: 200, body: async_response.to_json, headers: { 'Content-Type' => 'application/json' })

          error_response = { 'status' => 'error', 'error' => 'File not found' }
          stub_request(:get, %r{https://upload\.uploadcare\.com/from_url/status/})
            .to_return(status: 200, body: error_response.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'raises error when upload fails' do
          result = client.upload_from_url(source_url: source_url)
          expect(result.failure?).to be true
          expect(result.error.message).to match(/Upload from URL failed/)
        end
      end

      context 'with polling timeout' do
        before do
          stub_request(:post, 'https://upload.uploadcare.com/from_url/')
            .to_return(status: 200, body: async_response.to_json, headers: { 'Content-Type' => 'application/json' })

          waiting_response = { 'status' => 'waiting' }
          stub_request(:get, %r{https://upload\.uploadcare\.com/from_url/status/})
            .to_return(status: 200, body: waiting_response.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'raises timeout error after max polling time' do
          result = client.upload_from_url(source_url: source_url, poll_timeout: 0.1, poll_interval: 0.05)
          expect(result.failure?).to be true
          expect(result.error.message).to match(/polling timed out/)
        end
      end
    end

    describe '#upload_from_url_status' do
      let(:token) { 'token-uuid-1234' }
      let(:status_response) do
        {
          'status' => 'success',
          'uuid' => 'file-uuid-5678',
          'original_filename' => 'image.jpg',
          'size' => 54_321
        }
      end

      before do
        stub_request(:get, %r{https://upload\.uploadcare\.com/from_url/status/})
          .to_return(status: 200, body: status_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns status for valid token' do
        result = client.upload_from_url_status(token: token)

        expect(result).to be_a(Uploadcare::Result)
        expect(result.success).to have_key('status')
        expect(result.success['status']).to eq('success')
      end

      it 'returns file info on success' do
        result = client.upload_from_url_status(token: token)

        expect(result.success).to have_key('uuid')
        expect(result.success).to have_key('original_filename')
      end

      context 'with invalid token' do
        it 'raises ArgumentError for empty token' do
          result = client.upload_from_url_status(token: '')
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/token cannot be empty/)
        end

        it 'raises ArgumentError for nil token' do
          result = client.upload_from_url_status(token: nil)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/token cannot be empty/)
        end
      end

      context 'with different status states' do
        it 'handles waiting status' do
          waiting_response = { 'status' => 'waiting' }
          stub_request(:get, %r{https://upload\.uploadcare\.com/from_url/status/})
            .to_return(status: 200, body: waiting_response.to_json, headers: { 'Content-Type' => 'application/json' })

          result = client.upload_from_url_status(token: token)
          expect(result.success['status']).to eq('waiting')
        end

        it 'handles progress status' do
          progress_response = { 'status' => 'progress', 'progress' => 50 }
          stub_request(:get, %r{https://upload\.uploadcare\.com/from_url/status/})
            .to_return(status: 200, body: progress_response.to_json, headers: { 'Content-Type' => 'application/json' })

          result = client.upload_from_url_status(token: token)
          expect(result.success['status']).to eq('progress')
        end

        it 'handles error status' do
          error_response = { 'status' => 'error', 'error' => 'File not found' }
          stub_request(:get, %r{https://upload\.uploadcare\.com/from_url/status/})
            .to_return(status: 200, body: error_response.to_json, headers: { 'Content-Type' => 'application/json' })

          result = client.upload_from_url_status(token: token)
          expect(result.success['status']).to eq('error')
          expect(result.success).to have_key('error')
        end
      end
    end

    describe '#multipart_start' do
      let(:filename) { 'large_video.mp4' }
      let(:size) { 500_000_000 } # 500MB
      let(:content_type) { 'video/mp4' }
      let(:multipart_response) do
        {
          'uuid' => 'upload-uuid-1234',
          'parts' => [
            'https://s3.amazonaws.com/bucket/part1?signature=xxx',
            'https://s3.amazonaws.com/bucket/part2?signature=yyy',
            'https://s3.amazonaws.com/bucket/part3?signature=zzz'
          ]
        }
      end

      before do
        stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
          .to_return(status: 200, body: multipart_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      context 'with valid parameters' do
        it 'starts multipart upload successfully' do
          result = client.multipart_start(filename: filename, size: size, content_type: content_type)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success).to have_key('uuid')
          expect(result.success).to have_key('parts')
          expect(result.success['parts']).to be_an(Array)
        end

        it 'returns presigned URLs' do
          result = client.multipart_start(filename: filename, size: size, content_type: content_type)

          expect(result.success['parts'].length).to be > 0
          expect(result.success['parts'].first).to match(/^https:/)
        end

        it 'supports store option' do
          result = client.multipart_start(filename: filename, size: size, content_type: content_type, store: true)

          expect(result.success).to have_key('uuid')
        end

        it 'supports metadata' do
          metadata = { 'category' => 'videos' }
          result = client.multipart_start(filename: filename, size: size, content_type: content_type, metadata: metadata)

          expect(result.success).to have_key('uuid')
        end

        it 'supports custom part_size' do
          result = client.multipart_start(filename: filename, size: size, content_type: content_type,
                                          part_size: 10 * 1024 * 1024)

          expect(result.success).to have_key('uuid')
        end
      end

      context 'with invalid parameters' do
        it 'raises ArgumentError for empty filename' do
          result = client.multipart_start(filename: '', size: size, content_type: content_type)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/filename cannot be empty/)
        end

        it 'raises ArgumentError for nil filename' do
          result = client.multipart_start(filename: nil, size: size, content_type: content_type)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/filename cannot be empty/)
        end

        it 'raises ArgumentError for invalid size' do
          result = client.multipart_start(filename: filename, size: -1, content_type: content_type)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/size must be a positive integer/)
        end

        it 'raises ArgumentError for non-integer size' do
          result = client.multipart_start(filename: filename, size: 'not a number', content_type: content_type)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/size must be a positive integer/)
        end

        it 'raises ArgumentError for empty content_type' do
          result = client.multipart_start(filename: filename, size: size, content_type: '')
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/content_type cannot be empty/)
        end
      end
    end

    describe '#multipart_upload_part' do
      let(:presigned_url) { 'https://s3.amazonaws.com/bucket/part1?signature=xxx' }
      let(:part_data) { 'binary data content' * 1000 }

      before do
        stub_request(:put, presigned_url)
          .to_return(status: 200, body: '', headers: {})
      end

      context 'with valid parameters' do
        it 'uploads part successfully' do
          result = client.multipart_upload_part(presigned_url: presigned_url, part_data: part_data)

          expect(result.success).to be true
        end

        it 'handles IO objects' do
          io = StringIO.new(part_data)
          result = client.multipart_upload_part(presigned_url: presigned_url, part_data: io)

          expect(result.success).to be true
        end
      end

      context 'with invalid parameters' do
        it 'raises ArgumentError for empty presigned_url' do
          result = client.multipart_upload_part(presigned_url: '', part_data: part_data)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/presigned_url cannot be empty/)
        end

        it 'raises ArgumentError for nil presigned_url' do
          result = client.multipart_upload_part(presigned_url: nil, part_data: part_data)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/presigned_url cannot be empty/)
        end

        it 'raises ArgumentError for empty part_data' do
          result = client.multipart_upload_part(presigned_url: presigned_url, part_data: '')
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/part_data cannot be empty/)
        end

        it 'raises ArgumentError for nil part_data' do
          result = client.multipart_upload_part(presigned_url: presigned_url, part_data: nil)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/part_data cannot be nil/)
        end
      end

      context 'with network errors' do
        before do
          stub_request(:put, presigned_url)
            .to_return(status: 500, body: 'Internal Server Error')
        end

        it 'retries on failure' do
          result = client.multipart_upload_part(presigned_url: presigned_url, part_data: part_data, max_retries: 2)
          expect(result.failure?).to be true
          expect(result.error.message).to match(/Failed to upload part after 2 retries/)
        end
      end

      context 'with transient errors' do
        before do
          # First two attempts fail, third succeeds
          stub_request(:put, presigned_url)
            .to_return({ status: 500 }, { status: 500 }, { status: 200 })
        end

        it 'succeeds after retries' do
          result = client.multipart_upload_part(presigned_url: presigned_url, part_data: part_data, max_retries: 3)

          expect(result.success).to be true
        end
      end
    end

    describe '#multipart_complete' do
      let(:upload_uuid) { 'upload-uuid-1234' }
      let(:complete_response) do
        {
          'uuid' => 'file-uuid-5678',
          'original_filename' => 'large_video.mp4',
          'size' => 500_000_000,
          'mime_type' => 'video/mp4'
        }
      end

      before do
        stub_request(:post, 'https://upload.uploadcare.com/multipart/complete/')
          .to_return(status: 200, body: complete_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      context 'with valid uuid' do
        it 'completes multipart upload successfully' do
          result = client.multipart_complete(uuid: upload_uuid)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success).to have_key('uuid')
          expect(result.success['uuid']).to eq('file-uuid-5678')
        end

        it 'returns file information' do
          result = client.multipart_complete(uuid: upload_uuid)

          expect(result.success).to have_key('original_filename')
          expect(result.success).to have_key('size')
          expect(result.success).to have_key('mime_type')
        end
      end

      context 'with invalid uuid' do
        it 'raises ArgumentError for empty uuid' do
          result = client.multipart_complete(uuid: '')
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/uuid cannot be empty/)
        end

        it 'raises ArgumentError for nil uuid' do
          result = client.multipart_complete(uuid: nil)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/uuid cannot be empty/)
        end
      end
    end

    describe '#multipart_upload' do
      let(:file_path) { 'spec/fixtures/kitten.jpeg' }
      let(:file) { ::File.open(file_path, 'rb') }
      let(:file_size) { file.size }
      let(:multipart_response) do
        {
          'uuid' => 'upload-uuid-1234',
          'parts' => [
            'https://s3.amazonaws.com/bucket/part1?signature=xxx',
            'https://s3.amazonaws.com/bucket/part2?signature=yyy'
          ]
        }
      end
      let(:complete_response) do
        {
          'uuid' => 'file-uuid-5678',
          'original_filename' => 'kitten.jpeg',
          'size' => file_size
        }
      end

      before do
        stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
          .to_return(status: 200, body: multipart_response.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:put, /s3\.amazonaws\.com/)
          .to_return(status: 200, body: '', headers: {})

        stub_request(:post, 'https://upload.uploadcare.com/multipart/complete/')
          .to_return(status: 200, body: complete_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      after { file.close if file && !file.closed? }

      context 'with valid file' do
        it 'uploads file successfully' do
          result = client.multipart_upload(file: file, store: true)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success).to have_key('uuid')
          expect(result.success['uuid']).to eq('file-uuid-5678')
        end

        it 'calls all multipart methods in order' do
          expect(client).to receive(:multipart_start).and_call_original
          expect(client).to receive(:multipart_upload_part).at_least(:once).and_call_original
          expect(client).to receive(:multipart_complete).and_call_original

          client.multipart_upload(file: file, store: true)
        end

        it 'supports progress callback' do
          progress_calls = []

          client.multipart_upload(file: file, store: true) do |progress|
            progress_calls << progress
          end

          expect(progress_calls).not_to be_empty
          expect(progress_calls.last[:uploaded]).to be > 0
        end

        it 'supports metadata' do
          metadata = { 'category' => 'images' }
          result = client.multipart_upload(file: file, store: true, metadata: metadata)

          expect(result.success).to have_key('uuid')
        end
      end

      context 'with invalid file' do
        it 'raises ArgumentError for non-file object' do
          result = client.multipart_upload(file: 'not a file', store: true)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/file must be a File or IO object/)
        end

        it 'raises ArgumentError for nil' do
          result = client.multipart_upload(file: nil, store: true)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
        end
      end

      context 'with parallel uploads' do
        it 'uploads parts in parallel' do
          result = client.multipart_upload(file: file, store: true, threads: 2)

          expect(result.success).to have_key('uuid')
        end

        it 'tracks progress with parallel uploads' do
          progress_calls = []

          client.multipart_upload(file: file, store: true, threads: 2) do |progress|
            progress_calls << progress
          end

          expect(progress_calls).not_to be_empty
        end
      end
    end

    describe '#create_group' do
      let(:files) { %w[uuid-1 uuid-2 uuid-3] }
      let(:group_response) do
        {
          'id' => 'group-uuid~3',
          'datetime_created' => '2024-01-01T00:00:00Z',
          'datetime_stored' => nil,
          'files_count' => 3,
          'cdn_url' => 'https://ucarecdn.com/group-uuid~3/',
          'url' => 'https://api.uploadcare.com/groups/group-uuid~3/',
          'files' => files.map { |uuid| { 'uuid' => uuid } }
        }
      end

      before do
        stub_request(:post, 'https://upload.uploadcare.com/group/')
          .to_return(status: 200, body: group_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      context 'with valid files' do
        it 'creates a group successfully' do
          result = client.create_group(files: files)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success['id']).to eq('group-uuid~3')
          expect(result.success['files_count']).to eq(3)
        end

        it 'sends correct parameters' do
          client.create_group(files: files)

          expect(WebMock).to(have_requested(:post, 'https://upload.uploadcare.com/group/')
            .with { |req| req.body.include?('files%5B0%5D=uuid-1') && req.body.include?('pub_key=demopublickey') })
        end

        it 'supports signature parameter' do
          client.create_group(files: files, signature: 'test-signature', expire: 1_234_567_890)

          expect(WebMock).to have_requested(:post, 'https://upload.uploadcare.com/group/')
            .with(body: hash_including(
              'signature' => 'test-signature',
              'expire' => '1234567890'
            ))
        end
      end

      context 'with invalid input' do
        it 'raises ArgumentError for non-array' do
          result = client.create_group(files: 'not-an-array')
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/must be an array/)
        end

        it 'raises ArgumentError for empty array' do
          result = client.create_group(files: [])
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/cannot be empty/)
        end
      end
    end

    describe '#group_info' do
      let(:group_id) { 'group-uuid~3' }
      let(:group_info_response) do
        {
          'id' => group_id,
          'datetime_created' => '2024-01-01T00:00:00Z',
          'files_count' => 3,
          'cdn_url' => 'https://ucarecdn.com/group-uuid~3/',
          'files' => [
            { 'uuid' => 'uuid-1', 'size' => 1000 },
            { 'uuid' => 'uuid-2', 'size' => 2000 },
            { 'uuid' => 'uuid-3', 'size' => 3000 }
          ]
        }
      end

      before do
        stub_request(:get, %r{https://upload\.uploadcare\.com/group/info/})
          .to_return(status: 200, body: group_info_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      context 'with valid group_id' do
        it 'returns group information' do
          result = client.group_info(group_id: group_id)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success['id']).to eq(group_id)
          expect(result.success['files_count']).to eq(3)
          expect(result.success['files']).to be_an(Array)
          expect(result.success['files'].length).to eq(3)
        end

        it 'sends correct parameters' do
          client.group_info(group_id: group_id)

          expect(WebMock).to have_requested(:get, 'https://upload.uploadcare.com/group/info/')
            .with(query: hash_including(
              'pub_key' => config.public_key,
              'group_id' => group_id
            ))
        end
      end

      context 'with invalid group_id' do
        it 'raises ArgumentError for empty group_id' do
          result = client.group_info(group_id: '')
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/cannot be empty/)
        end

        it 'raises ArgumentError for nil group_id' do
          result = client.group_info(group_id: nil)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/cannot be empty/)
        end
      end
    end

    describe '#file_info' do
      let(:file_id) { 'file-uuid-1234' }
      let(:file_info_response) do
        {
          'uuid' => file_id,
          'size' => 12_345,
          'mime_type' => 'image/jpeg',
          'original_filename' => 'test.jpg',
          'is_image' => true,
          'is_ready' => true,
          'datetime_uploaded' => '2024-01-01T00:00:00Z'
        }
      end

      before do
        stub_request(:get, %r{https://upload\.uploadcare\.com/info/})
          .to_return(status: 200, body: file_info_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      context 'with valid file_id' do
        it 'returns file information' do
          result = client.file_info(file_id: file_id)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success['uuid']).to eq(file_id)
          expect(result.success['size']).to eq(12_345)
          expect(result.success['mime_type']).to eq('image/jpeg')
        end

        it 'sends correct parameters' do
          client.file_info(file_id: file_id)

          expect(WebMock).to have_requested(:get, 'https://upload.uploadcare.com/info/')
            .with(query: hash_including(
              'pub_key' => config.public_key,
              'file_id' => file_id
            ))
        end
      end

      context 'with invalid file_id' do
        it 'raises ArgumentError for empty file_id' do
          result = client.file_info(file_id: '')
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/cannot be empty/)
        end

        it 'raises ArgumentError for nil file_id' do
          result = client.file_info(file_id: nil)
          expect(result.failure?).to be true
          expect(result.error).to be_a(ArgumentError)
          expect(result.error.message).to match(/cannot be empty/)
        end
      end
    end
  end
end
