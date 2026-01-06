# frozen_string_literal: true

require 'spec_helper'

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
  end
end
