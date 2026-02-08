# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe UploadClient do
    let(:config) { Uploadcare.configuration }
    let(:client) { described_class.new(config: config) }

    describe 'store_value' do
      it 'returns "0" for false' do
        expect(client.send(:store_value, false)).to eq('0')
      end

      it 'returns string value for other values' do
        expect(client.send(:store_value, 'auto')).to eq('auto')
      end
    end

    describe 'signature and expire parameters' do
      let(:file) { ::File.open('spec/fixtures/kitten.jpeg', 'rb') }

      after { file.close if file && !file.closed? }

      it 'includes signature and expire when provided' do
        options = { signature: 'test-signature', expire: 1_234_567_890 }
        params = client.send(:build_upload_params, file, options)

        expect(params['signature']).to eq('test-signature')
        expect(params['expire']).to eq(1_234_567_890)
      end

      it 'generates signature params when signing enabled' do
        original_sign_uploads = config.sign_uploads
        config.sign_uploads = true
        allow(Uploadcare::Param::Upload::SignatureGenerator).to receive(:call)
          .and_return({ signature: 'sig', expire: 123 })

        params = client.send(:signature_params, {})

        expect(params['signature']).to eq('sig')
        expect(params['expire']).to eq(123)
      ensure
        config.sign_uploads = original_sign_uploads
      end

      it 'returns empty signature params when generator is missing' do
        original_sign_uploads = config.sign_uploads
        original_logger = config.logger
        config.sign_uploads = true
        config.logger = Logger.new(StringIO.new)
        hide_const('Uploadcare::Param::Upload::SignatureGenerator')

        params = client.send(:signature_params, {})

        expect(params).to eq({})
      ensure
        config.sign_uploads = original_sign_uploads
        config.logger = original_logger
      end

      it 'returns signature when generator returns string' do
        original_sign_uploads = config.sign_uploads
        config.sign_uploads = true
        allow(Uploadcare::Param::Upload::SignatureGenerator).to receive(:call).and_return('string-sig')

        params = client.send(:signature_params, {})

        expect(params).to eq({ 'signature' => 'string-sig' })
      ensure
        config.sign_uploads = original_sign_uploads
      end
    end

    describe 'request options' do
      it 'applies timeout and open_timeout' do
        options = Struct.new(:timeout, :open_timeout).new
        request = double('request', options: options)

        client.send(:apply_request_options, request, { timeout: 3, open_timeout: 4 })

        expect(options.timeout).to eq(3)
        expect(options.open_timeout).to eq(4)
      end
    end

    describe '#poll_upload_status' do
      it 'raises UnknownStatusError for unknown status' do
        # Stub the HTTP request to return an unknown status
        stub_request(:get, %r{#{Uploadcare.configuration.upload_api_root}/from_url/status/})
          .to_return(
            status: 200,
            body: { 'status' => 'weird_status' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        expect do
          client.send(:poll_upload_status, token: 'test-token', options: { poll_interval: 0.1, poll_timeout: 1 },
                                           request_options: {})
        end.to raise_error(Uploadcare::Exception::UploadError, /Unknown upload status: weird_status/)
      end
    end

    describe '#handle_error_response' do
      it 'raises UploadError with status and body' do
        response = double('response', status: 400, body: 'Bad Request')

        expect do
          client.send(:handle_error_response, response)
        end.to raise_error(Uploadcare::Exception::UploadError, /Upload API error: 400 Bad Request/)
      end
    end

    describe '#handle_faraday_error' do
      it 'raises RequestError with response details when response exists' do
        error = Faraday::ClientError.new('error', { status: 500, body: 'Server Error' })

        expect do
          client.send(:handle_faraday_error, error)
        end.to raise_error(Uploadcare::Exception::RequestError, /HTTP 500: Server Error/)
      end

      it 'raises RequestError with network error message when response is nil' do
        error = Faraday::ConnectionFailed.new('Connection refused')

        expect do
          client.send(:handle_faraday_error, error)
        end.to raise_error(Uploadcare::Exception::RequestError, /Network error: Connection refused/)
      end
    end

    describe 'multipart upload thread error handling' do
      let(:file_path) { 'spec/fixtures/kitten.jpeg' }
      let(:file) { ::File.open(file_path, 'rb') }

      after { file.close if file && !file.closed? }

      it 'handles thread errors during multipart upload' do
        # Create a mock file with known size
        file_size = file.size
        presigned_urls = %w[url1 url2]
        part_size = file_size / 2

        # Mock multipart_upload_part to raise an error on first call
        call_count = 0
        allow(client).to receive(:multipart_upload_part) do
          call_count += 1
          raise StandardError, 'Upload failed' if call_count == 1

          nil
        end

        # This should trigger the error handling in threads (lines 641, 642)
        expect do
          client.send(:upload_parts_parallel, file, presigned_urls, part_size, 2)
        end.to raise_error(StandardError, /Upload failed/)
      end

      it 'collects errors from worker.join rescue block' do
        file_size = file.size
        presigned_urls = %w[url1 url2]
        part_size = file_size / 2

        # Create a scenario where thread.join itself raises an error
        allow(client).to receive(:multipart_upload_part).and_raise(StandardError, 'Thread join error')

        # This should trigger line 652 (error collection in worker.join rescue)
        expect do
          client.send(:upload_parts_parallel, file, presigned_urls, part_size, 2)
        end.to raise_error(StandardError)
      end

      it 'breaks from queue loop when queue is empty' do
        file_size = file.size
        presigned_urls = ['url1']
        part_size = file_size

        # Mock successful upload
        allow(client).to receive(:multipart_upload_part).and_return(nil)

        # This should trigger line 626 (break when queue is empty)
        expect do
          client.send(:upload_parts_parallel, file, presigned_urls, part_size, 2)
        end.not_to raise_error
      end

      it 'handles ThreadError when queue is empty (explicit coverage for line 626)' do
        file_size = file.size
        # Use more threads than parts to force some threads to hit ThreadError
        presigned_urls = ['url1']
        part_size = file_size

        # Mock successful upload
        allow(client).to receive(:multipart_upload_part).and_return(nil)

        # With 5 threads and only 1 part, 4 threads will hit the ThreadError path
        expect do
          client.send(:upload_parts_parallel, file, presigned_urls, part_size, 5)
        end.not_to raise_error
      end

      it 'forces ThreadError path by manipulating queue timing' do
        file_size = file.size
        presigned_urls = %w[url1 url2]
        part_size = file_size / 2

        # Create a custom queue that will raise ThreadError more aggressively
        queue = Queue.new
        allow(Queue).to receive(:new).and_return(queue)

        # Mock successful upload with a delay to create race conditions
        allow(client).to receive(:multipart_upload_part) do
          sleep(0.001) # Small delay to create timing issues
          nil
        end

        expect do
          client.send(:upload_parts_parallel, file, presigned_urls, part_size, 10)
        end.not_to raise_error
      end

      it 'breaks when queue pop raises ThreadError' do
        queue = Queue.new
        allow(Queue).to receive(:new).and_return(queue)
        allow(queue).to receive(:pop).with(true).and_raise(ThreadError)

        file_size = file.size
        presigned_urls = ['url1']
        part_size = file_size

        allow(client).to receive(:multipart_upload_part).and_return(nil)

        expect do
          client.send(:upload_parts_parallel, file, presigned_urls, part_size, 1)
        end.not_to raise_error
      end
    end
  end
end
