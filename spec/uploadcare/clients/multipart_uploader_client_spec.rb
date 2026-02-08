# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe MultipartUploaderClient do
    let(:config) { Uploadcare.configuration }
    let(:client) { described_class.new(config: config) }
    let(:file_path) { 'spec/fixtures/kitten.jpeg' }
    let(:file) { ::File.open(file_path, 'rb') }
    let(:uuid) { 'upload-uuid-1234' }

    after { file.close if file && !file.closed? }

    describe 'CHUNK_SIZE' do
      it 'has correct chunk size constant' do
        expect(described_class::CHUNK_SIZE).to eq(5_242_880)
      end
    end

    describe '#upload' do
      let(:upload_start_response) do
        {
          'uuid' => uuid,
          'parts' => [
            'https://s3.amazonaws.com/bucket/part1?signature=xxx',
            'https://s3.amazonaws.com/bucket/part2?signature=yyy'
          ]
        }
      end
      let(:upload_complete_response) do
        {
          'uuid' => 'file-uuid-5678',
          'original_filename' => 'kitten.jpeg',
          'size' => file.size
        }
      end

      before do
        stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
          .to_return(status: 200, body: upload_start_response.to_json, headers: { 'Content-Type' => 'application/json' })

        # Mock the put method to avoid actual S3 requests
        allow(client).to receive(:put).and_call_original
        allow(client).to receive(:put).with(/s3\.amazonaws\.com/, anything).and_return(true)

        stub_request(:post, 'https://upload.uploadcare.com/multipart/complete/')
          .to_return(status: 200, body: upload_complete_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      context 'with successful upload' do
        it 'uploads file and returns uuid' do
          result = client.upload(file: file)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success).to have_key('uuid')
          expect(result.success['uuid']).to eq(uuid)
        end

        it 'calls upload_start, upload_chunks, and upload_complete' do
          expect(client).to receive(:upload_start).and_call_original
          expect(client).to receive(:upload_chunks).and_call_original
          expect(client).to receive(:upload_complete).and_call_original

          client.upload(file: file)
        end

        it 'supports store option' do
          result = client.upload(file: file, store: true)

          expect(result.success).to have_key('uuid')
        end

        it 'supports metadata' do
          metadata = { 'category' => 'images' }
          result = client.upload(file: file, metadata: metadata)

          expect(result.success).to have_key('uuid')
        end

        it 'supports progress callback' do
          progress_calls = []

          client.upload(file: file) do |progress|
            progress_calls << progress
          end

          expect(progress_calls).not_to be_empty
          expect(progress_calls.first).to have_key(:chunk_size)
          expect(progress_calls.first).to have_key(:offset)
          expect(progress_calls.first).to have_key(:link_index)
        end
      end

      context 'when upload_start returns no parts' do
        let(:incomplete_response) { { 'uuid' => uuid } }

        before do
          stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
            .to_return(status: 200, body: incomplete_response.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'returns response without completing upload' do
          result = client.upload(file: file)

          expect(result.success).to eq(incomplete_response)
          expect(WebMock).not_to have_requested(:post, 'https://upload.uploadcare.com/multipart/complete/')
        end
      end

      context 'when upload_start returns no uuid' do
        let(:incomplete_response) { { 'parts' => %w[url1 url2] } }

        before do
          stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
            .to_return(status: 200, body: incomplete_response.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'returns response without completing upload' do
          result = client.upload(file: file)

          expect(result.success).to eq(incomplete_response)
          expect(WebMock).not_to have_requested(:post, 'https://upload.uploadcare.com/multipart/complete/')
        end
      end
    end

    describe '#upload_start' do
      let(:multipart_response) do
        {
          'uuid' => uuid,
          'parts' => [
            'https://s3.amazonaws.com/bucket/part1?signature=xxx',
            'https://s3.amazonaws.com/bucket/part2?signature=yyy'
          ]
        }
      end

      before do
        stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
          .to_return(status: 200, body: multipart_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'starts multipart upload' do
        result = client.upload_start(file: file)

        expect(result).to be_a(Uploadcare::Result)
        expect(result.success).to have_key('uuid')
        expect(result.success).to have_key('parts')
      end

      it 'sends correct file parameters' do
        client.upload_start(file: file)

        expect(WebMock).to(have_requested(:post, 'https://upload.uploadcare.com/multipart/start/')
          .with { |req| req.body.include?('filename') && req.body.include?('size') && req.body.include?('content_type') })
      end

      it 'includes public key' do
        client.upload_start(file: file)

        expect(WebMock).to(have_requested(:post, 'https://upload.uploadcare.com/multipart/start/')
          .with { |req| req.body.include?('UPLOADCARE_PUB_KEY') })
      end

      it 'supports store option' do
        client.upload_start(file: file, store: true)

        expect(WebMock).to(have_requested(:post, 'https://upload.uploadcare.com/multipart/start/')
          .with { |req| req.body.include?('UPLOADCARE_STORE') })
      end

      it 'supports metadata' do
        metadata = { 'tag' => 'test' }
        client.upload_start(file: file, metadata: metadata)

        expect(WebMock).to have_requested(:post, 'https://upload.uploadcare.com/multipart/start/')
      end
    end

    describe '#upload_complete' do
      let(:complete_response) do
        {
          'uuid' => 'file-uuid-5678',
          'original_filename' => 'kitten.jpeg',
          'size' => 12_345
        }
      end

      before do
        stub_request(:post, 'https://upload.uploadcare.com/multipart/complete/')
          .to_return(status: 200, body: complete_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'completes multipart upload' do
        result = client.upload_complete(uuid: uuid)

        expect(result).to be_a(Uploadcare::Result)
        expect(result.success).to have_key('uuid')
      end

      it 'sends correct parameters' do
        client.upload_complete(uuid: uuid)

        expect(WebMock).to(have_requested(:post, 'https://upload.uploadcare.com/multipart/complete/')
          .with { |req| req.body.include?('UPLOADCARE_PUB_KEY') && req.body.include?('uuid') })
      end
    end

    describe '#upload_chunks' do
      let(:links) do
        [
          'https://s3.amazonaws.com/bucket/part1?signature=xxx',
          'https://s3.amazonaws.com/bucket/part2?signature=yyy'
        ]
      end

      before do
        allow(client).to receive(:put).with(/s3\.amazonaws\.com/, anything).and_return(true)
      end

      it 'uploads all chunks' do
        client.send(:upload_chunks, file, links)

        expect(client).to have_received(:put).with(/s3\.amazonaws\.com/, anything).twice
      end

      it 'calls progress callback for each chunk' do
        progress_calls = []

        client.send(:upload_chunks, file, links) do |progress|
          progress_calls << progress
        end

        expect(progress_calls.length).to eq(2)
        expect(progress_calls.first).to have_key(:chunk_size)
        expect(progress_calls.first).to have_key(:offset)
        expect(progress_calls.first).to have_key(:link_index)
        expect(progress_calls.first).to have_key(:links_count)
      end
    end

    describe '#process_chunk' do
      let(:links) { ['https://s3.amazonaws.com/bucket/part1?signature=xxx'] }
      let(:link_index) { 0 }

      before do
        allow(client).to receive(:put).with(/s3\.amazonaws\.com/, anything).and_return(true)
      end

      it 'uploads a single chunk' do
        client.send(:process_chunk, file, links, link_index)

        expect(client).to have_received(:put).with(links[0], anything)
      end

      it 'calls progress callback with correct parameters' do
        callback_called = false

        client.send(:process_chunk, file, links, link_index) do |progress|
          callback_called = true
          expect(progress[:chunk_size]).to eq(described_class::CHUNK_SIZE)
          expect(progress[:offset]).to eq(0)
          expect(progress[:link_index]).to eq(0)
          expect(progress[:links_count]).to eq(1)
        end

        expect(callback_called).to be true
      end

      context 'with error' do
        before do
          allow(client).to receive(:put).with(/s3\.amazonaws\.com/, anything).and_raise(StandardError.new('Upload failed'))
        end

        it 'logs error and re-raises' do
          expect(config.logger).to receive(:error).with(/Chunk upload failed/)

          expect do
            client.send(:process_chunk, file, links, link_index)
          end.to raise_error(StandardError, 'Upload failed')
        end
      end
    end

    describe '#multipart_start_params' do
      it 'builds correct parameters' do
        params = client.send(:multipart_start_params, file, {})

        expect(params).to have_key('UPLOADCARE_PUB_KEY')
        expect(params).to have_key('filename')
        expect(params).to have_key('size')
        expect(params).to have_key('content_type')
      end

      it 'includes store option' do
        params = client.send(:multipart_start_params, file, store: true)

        expect(params).to have_key('UPLOADCARE_STORE')
        expect(params['UPLOADCARE_STORE']).to eq('1')
      end

      it 'includes metadata' do
        metadata = { 'tag' => 'test' }
        params = client.send(:multipart_start_params, file, metadata: metadata)

        expect(params).to be_a(Hash)
      end
    end

    describe '#generate_upload_params' do
      it 'generates basic upload parameters' do
        params = client.send(:generate_upload_params, {})

        expect(params).to have_key('UPLOADCARE_PUB_KEY')
        expect(params['UPLOADCARE_PUB_KEY']).to eq(config.public_key)
      end

      it 'includes store value' do
        params = client.send(:generate_upload_params, store: true)

        expect(params).to have_key('UPLOADCARE_STORE')
        expect(params['UPLOADCARE_STORE']).to eq('1')
      end

      it 'removes nil values' do
        params = client.send(:generate_upload_params, {})

        expect(params.values).not_to include(nil)
      end

      context 'with signing enabled' do
        before do
          allow(config).to receive(:sign_uploads).and_return(true)
        end

        it 'adds signature when generator returns string' do
          allow(Uploadcare::Param::Upload::SignatureGenerator).to receive(:call).and_return('test-signature')

          params = client.send(:generate_upload_params, {})

          expect(params['signature']).to eq('test-signature')
        end

        it 'adds expire when generator returns hash' do
          allow(Uploadcare::Param::Upload::SignatureGenerator).to receive(:call)
            .and_return({ signature: 'test-signature', expire: 123 })

          params = client.send(:generate_upload_params, {})

          expect(params['signature']).to eq('test-signature')
          expect(params['expire']).to eq(123)
        end
      end
    end

    describe '#multipart_file_params' do
      it 'extracts file parameters' do
        params = client.send(:multipart_file_params, file)

        expect(params).to have_key('filename')
        expect(params).to have_key('size')
        expect(params).to have_key('content_type')
      end

      it 'uses original_filename if available' do
        allow(file).to receive(:respond_to?).with(:original_filename).and_return(true)
        allow(file).to receive(:original_filename).and_return('custom_name.jpg')

        params = client.send(:multipart_file_params, file)

        expect(params['filename']).to eq('custom_name.jpg')
      end

      it 'uses basename as fallback' do
        params = client.send(:multipart_file_params, file)

        expect(params['filename']).to eq('kitten.jpeg')
      end

      it 'detects correct MIME type' do
        params = client.send(:multipart_file_params, file)

        expect(params['content_type']).to eq('image/jpeg')
      end

      it 'uses default content type for unknown files' do
        allow(MIME::Types).to receive(:type_for).and_return([])

        params = client.send(:multipart_file_params, file)

        expect(params['content_type']).to eq('application/octet-stream')
      end

      it 'converts size to string' do
        params = client.send(:multipart_file_params, file)

        expect(params['size']).to be_a(String)
        expect(params['size'].to_i).to eq(file.size)
      end
    end

    describe '#form_data_for' do
      it 'returns multipart file params' do
        result = client.send(:form_data_for, file)

        expect(result).to have_key('filename')
        expect(result).to have_key('size')
        expect(result).to have_key('content_type')
      end
    end
  end
end
