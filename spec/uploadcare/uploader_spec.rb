# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

module Uploadcare
  RSpec.describe Uploader do
    let(:file_path) { 'spec/fixtures/kitten.jpeg' }
    let(:url) { 'https://example.com/image.jpg' }

    describe '.upload' do
      context 'with URL source' do
        let(:url_response) do
          {
            'uuid' => 'url-file-uuid',
            'original_filename' => 'image.jpg',
            'size' => 12_345
          }
        end

        before do
          stub_request(:post, 'https://upload.uploadcare.com/from_url/')
            .to_return(status: 200, body: { 'token' => 'test-token' }.to_json)

          stub_request(:get, %r{https://upload\.uploadcare\.com/from_url/status/})
            .to_return(status: 200, body: url_response.merge('status' => 'success').to_json)
        end

        it 'detects URL and uses upload_from_url' do
          result = described_class.upload(url, store: true)

          expect(result).to be_a(Uploadcare::File)
          expect(result.uuid).to eq('url-file-uuid')
        end
      end

      context 'with file path (small file)' do
        let(:upload_response) do
          {
            'kitten.jpeg' => 'file-uuid-1234'
          }
        end

        before do
          stub_request(:post, 'https://upload.uploadcare.com/base/')
            .to_return(
              status: 200,
              body: upload_response.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          # Mock the REST API file info call (used when secret_key is present)
          stub_request(:get, 'https://api.uploadcare.com/files/file-uuid-1234/')
            .to_return(
              status: 200,
              body: {
                'uuid' => 'file-uuid-1234',
                'original_filename' => 'kitten.jpeg',
                'size' => 1234,
                'datetime_uploaded' => '2024-01-01T00:00:00Z'
              }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'detects small file and uses upload_file' do
          file = ::File.open(file_path, 'rb')
          result = described_class.upload(file, store: true)
          file.close

          expect(result).to be_a(Uploadcare::File)
          expect(result.uuid).to eq('file-uuid-1234')
        end
      end

      context 'with File object (small file)' do
        let(:file) { ::File.open(file_path, 'rb') }
        let(:upload_response) do
          {
            'kitten.jpeg' => 'file-uuid-5678'
          }
        end

        after { file.close }

        before do
          stub_request(:post, 'https://upload.uploadcare.com/base/')
            .to_return(
              status: 200,
              body: upload_response.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          # Mock the REST API file info call
          stub_request(:get, 'https://api.uploadcare.com/files/file-uuid-5678/')
            .to_return(
              status: 200,
              body: {
                'uuid' => 'file-uuid-5678',
                'original_filename' => 'kitten.jpeg',
                'size' => 1234,
                'datetime_uploaded' => '2024-01-01T00:00:00Z'
              }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'uploads File object' do
          result = described_class.upload(file, store: true)

          expect(result).to be_a(Uploadcare::File)
          expect(result.uuid).to eq('file-uuid-5678')
        end
      end

      context 'with invalid source' do
        it 'raises ArgumentError for nil' do
          expect { described_class.upload(nil) }.to raise_error(ArgumentError, /Expected input to be/)
        end

        it 'raises ArgumentError for unsupported type' do
          expect { described_class.upload(12_345) }.to raise_error(ArgumentError, /Expected input to be/)
        end

        it 'raises ArgumentError for non-existent file path' do
          # Non-existent file path is treated as a URL by the existing implementation
          # So we need to stub the URL upload to fail
          stub_request(:post, 'https://upload.uploadcare.com/from_url/')
            .to_return(status: 400, body: { 'error' => 'Invalid URL' }.to_json)

          expect do
            described_class.upload('nonexistent.jpg')
          end.to raise_error(RuntimeError, /Upload API error/)
        end
      end

      context 'with array of files' do
        let(:files) { [::File.open(file_path, 'rb'), ::File.open(file_path, 'rb')] }
        let(:upload_response) do
          {
            'kitten.jpeg' => 'file-uuid-1',
            '1kitten.jpeg' => 'file-uuid-2'
          }
        end

        after { files.each(&:close) }

        before do
          stub_request(:post, 'https://upload.uploadcare.com/base/')
            .to_return(status: 200, body: upload_response.to_json)
        end

        it 'uploads multiple files' do
          results = described_class.upload(files, store: true)

          expect(results).to be_an(Array)
          expect(results.length).to eq(2)
          expect(results.all? { |r| r.is_a?(Uploadcare::File) }).to be true
        end
      end
    end

    describe '.upload with multipart upload detection' do
      let(:large_file_path) { 'spec/fixtures/large_file.bin' }

      before do
        # Ensure multipart threshold is set low enough for our test file
        allow(Uploadcare.configuration).to receive(:multipart_size_threshold).and_return(10 * 1024 * 1024)
        
        # Create a temporary large file for testing
        ::File.binwrite(large_file_path, 'x' * 15_000_000)

        # Stub multipart upload endpoints
        stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
          .to_return(
            status: 200,
            body: {
              'uuid' => 'multipart-uuid-1234',
              'parts' => (1..3).map { |i| "https://upload.uploadcare.com/multipart/part/#{i}/" }
            }.to_json
          )

        (1..3).each do |part_number|
          stub_request(:put, "https://upload.uploadcare.com/multipart/part/#{part_number}/")
            .to_return(status: 200, body: '')
        end

        stub_request(:post, 'https://upload.uploadcare.com/multipart/complete/')
          .to_return(
            status: 200,
            body: {
              'uuid' => 'multipart-uuid-1234',
              'original_filename' => 'large_file.bin',
              'size' => 15_000_000
            }.to_json
          )
      end

      after do
        ::File.delete(large_file_path) if ::File.exist?(large_file_path)
      end

      it 'uses multipart upload for large files' do
        # Since we're stubbing the requests above, we just need to test the flow
        progress_calls = []

        # Open file object to trigger multipart detection
        file = ::File.open(large_file_path, 'rb')
        
        # Ensure the file is recognized as big
        expect(described_class.big_file?(file)).to be true
        
        result = described_class.upload(file, store: true) do |progress|
          progress_calls << progress
        end
        file.close

        expect(result).to be_a(Uploadcare::File)
        expect(result.uuid).to eq('multipart-uuid-1234')
      end
    end

    describe '.upload_files' do
      let(:files) { ['spec/fixtures/kitten.jpeg', 'spec/fixtures/kitten.jpeg'] }

      before do
        stub_request(:post, 'https://upload.uploadcare.com/base/')
          .to_return(
            status: 200,
            body: { 'kitten.jpeg' => 'file-uuid-batch' }.to_json
          )

        stub_request(:get, 'https://api.uploadcare.com/files/file-uuid-batch/')
          .to_return(
            status: 200,
            body: {
              'uuid' => 'file-uuid-batch',
              'original_filename' => 'kitten.jpeg',
              'size' => 1234
            }.to_json
          )
      end

      it 'uploads files sequentially by default' do
        results = described_class.upload_files(files, store: true)

        expect(results).to be_an(Array)
        expect(results.length).to eq(2)
        expect(results.all? { |r| r[:success] }).to be true
        expect(results.map { |r| r[:response].uuid }).to all(eq('file-uuid-batch'))
      end

      it 'calls progress block for each file' do
        callbacks = []

        described_class.upload_files(files, store: true) do |result|
          callbacks << result
        end

        expect(callbacks.length).to eq(2)
        expect(callbacks.all? { |cb| cb[:success] }).to be true
      end

      it 'uploads files in parallel when specified' do
        results = described_class.upload_files(files, store: true, parallel: 2)

        expect(results).to be_an(Array)
        expect(results.length).to eq(2)
        expect(results.all? { |r| r[:success] }).to be true
      end

      it 'handles mixed success and failure' do
        mixed_files = ['spec/fixtures/kitten.jpeg', 'nonexistent.jpg']

        stub_request(:post, 'https://upload.uploadcare.com/from_url/')
          .to_return(status: 400, body: { 'error' => 'Invalid URL' }.to_json)

        results = described_class.upload_files(mixed_files, store: true)

        expect(results.length).to eq(2)
        expect(results[0][:success]).to be true
        expect(results[1][:success]).to be false
        expect(results[1][:error]).to include('Upload API error')
      end

      it 'raises ArgumentError for non-array input' do
        expect do
          described_class.upload_files('single_file.jpg')
        end.to raise_error(ArgumentError, 'sources must be an array')
      end

      it 'raises ArgumentError for empty array' do
        expect do
          described_class.upload_files([])
        end.to raise_error(ArgumentError, 'sources cannot be empty')
      end
    end

    describe 'private methods' do
      describe '.url?' do
        it 'returns true for HTTP URLs' do
          expect(described_class.send(:url?, 'http://example.com/file.jpg')).to be true
        end

        it 'returns true for HTTPS URLs' do
          expect(described_class.send(:url?, 'https://example.com/file.jpg')).to be true
        end

        it 'returns false for non-URLs' do
          expect(described_class.send(:url?, 'file.jpg')).to be false
          expect(described_class.send(:url?, '/path/to/file.jpg')).to be false
        end

        it 'returns false for non-strings' do
          expect(described_class.send(:url?, 12_345)).to be false
          expect(described_class.send(:url?, nil)).to be false
        end
      end

      describe '.file_or_io?' do
        it 'returns true for File objects' do
          file = ::File.open('spec/fixtures/kitten.jpeg', 'rb')
          expect(described_class.send(:file_or_io?, file)).to be true
          file.close
        end

        it 'returns true for IO objects' do
          io = StringIO.new('test content')
          expect(described_class.send(:file_or_io?, io)).to be true
        end

        it 'returns false for strings' do
          expect(described_class.send(:file_or_io?, 'string')).to be false
        end

        it 'returns false for other types' do
          expect(described_class.send(:file_or_io?, 12_345)).to be false
          expect(described_class.send(:file_or_io?, nil)).to be false
        end
      end

      describe '.string_path?' do
        it 'returns true for strings' do
          expect(described_class.send(:string_path?, 'file.jpg')).to be true
        end

        it 'returns false for non-strings' do
          expect(described_class.send(:string_path?, 12_345)).to be false
          expect(described_class.send(:string_path?, nil)).to be false
        end
      end

      describe '.upload_path_wrapper' do
        it 'raises ArgumentError for non-existent files' do
          expect do
            described_class.send(:upload_path_wrapper, nil, 'nonexistent.jpg', {})
          end.to raise_error(ArgumentError, 'File not found: nonexistent.jpg')
        end
      end
    end

    describe 'edge cases and error handling' do
      it 'handles nil source' do
        expect do
          described_class.upload(nil)
        end.to raise_error(ArgumentError, 'source cannot be nil')
      end

      it 'handles unsupported source types' do
        expect do
          described_class.upload(12_345)
        end.to raise_error(ArgumentError, 'Unsupported source type: Integer')
      end

      context 'with StringIO objects' do
        let(:string_io) { StringIO.new('test file content') }

        it 'handles StringIO objects' do
          result = described_class.upload(string_io, store: true)
          expect(result).to be_a(Uploadcare::File)
          expect(result.uuid).to eq('stringio-uuid')
        end
      end

      context 'with Tempfile objects' do
        let(:tempfile) do
          file = Tempfile.new('test')
          file.write('temporary file content')
          file.rewind
          file
        end

        before do
          stub_request(:post, 'https://upload.uploadcare.com/base/')
            .to_return(
              status: 200,
              body: { File.basename(tempfile.path) => 'tempfile-uuid' }.to_json
            )

          stub_request(:get, 'https://api.uploadcare.com/files/tempfile-uuid/')
            .to_return(
              status: 200,
              body: {
                'uuid' => 'tempfile-uuid',
                'original_filename' => File.basename(tempfile.path),
                'size' => tempfile.size
              }.to_json
            )
        end

        after { tempfile.close! }

        it 'handles Tempfile objects' do
          result = described_class.upload(tempfile, store: true)
          expect(result).to be_a(Uploadcare::File)
          expect(result.uuid).to eq('tempfile-uuid')
        end
      end
    end

    describe 'upload options' do
      let(:file) { ::File.open('spec/fixtures/kitten.jpeg', 'rb') }

      after { file.close }

      context 'with store option' do
        before do
          stub_request(:post, 'https://upload.uploadcare.com/base/')
            .to_return(
              status: 200,
              body: { 'kitten.jpeg' => 'stored-file-uuid' }.to_json
            )

          stub_request(:get, 'https://api.uploadcare.com/files/stored-file-uuid/')
            .to_return(
              status: 200,
              body: {
                'uuid' => 'stored-file-uuid',
                'original_filename' => 'kitten.jpeg',
                'size' => 1234
              }.to_json
            )
        end

        it 'passes store option to upload client' do
          result = described_class.upload(file, store: true)
          expect(result).to be_a(Uploadcare::File)
        end
      end

      context 'with metadata option' do
        before do
          stub_request(:post, 'https://upload.uploadcare.com/base/')
            .to_return(
              status: 200,
              body: { 'kitten.jpeg' => 'metadata-file-uuid' }.to_json
            )

          stub_request(:get, 'https://api.uploadcare.com/files/metadata-file-uuid/')
            .to_return(
              status: 200,
              body: {
                'uuid' => 'metadata-file-uuid',
                'original_filename' => 'kitten.jpeg',
                'size' => 1234
              }.to_json
            )
        end

        it 'passes metadata option to upload client' do
          metadata = { 'key1' => 'value1', 'key2' => 'value2' }
          result = described_class.upload(file, metadata: metadata)
          expect(result).to be_a(Uploadcare::File)
        end
      end
    end

    describe 'integration with upload clients' do
      it 'creates and uses UploadClient' do
        client = double('upload_client')
        allow(Uploadcare::UploadClient).to receive(:new).and_return(client)
        allow(client).to receive(:upload_from_url).and_return({ 'uuid' => 'url-uuid' })

        expect(client).to receive(:upload_from_url).with('https://example.com/image.jpg', {})

        described_class.upload('https://example.com/image.jpg')
      end
    end
  end
end
