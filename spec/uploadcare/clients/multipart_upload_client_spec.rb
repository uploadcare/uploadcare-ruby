# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::MultipartUploadClient do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'test_public_key',
      secret_key: 'test_secret_key'
    )
  end
  
  subject(:client) { described_class.new(config) }

  describe '#start' do
    let(:filename) { 'test_file.bin' }
    let(:size) { 10 * 1024 * 1024 } # 10MB
    let(:mock_response) do
      {
        'uuid' => 'upload-uuid-123',
        'parts' => [
          {
            'url' => 'https://s3.amazonaws.com/bucket/part1',
            'start_offset' => 0,
            'end_offset' => 5242880
          },
          {
            'url' => 'https://s3.amazonaws.com/bucket/part2',
            'start_offset' => 5242880,
            'end_offset' => 10485760
          }
        ]
      }
    end

    it 'starts multipart upload' do
      stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
        .with(
          body: hash_including(
            'filename' => filename,
            'size' => size.to_s,
            'content_type' => 'application/octet-stream',
            'UPLOADCARE_STORE' => 'auto',
            'pub_key' => 'test_public_key'
          )
        )
        .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.start(filename, size)
      expect(result).to eq(mock_response)
      expect(result['uuid']).to eq('upload-uuid-123')
      expect(result['parts']).to be_an(Array)
    end

    it 'includes metadata in request' do
      stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
        .with(
          body: hash_including(
            'metadata[key1]' => 'value1',
            'metadata[key2]' => 'value2'
          )
        )
        .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })

      client.start(filename, size, 'application/octet-stream', metadata: { key1: 'value1', key2: 'value2' })
    end

    it 'respects store option' do
      stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
        .with(
          body: hash_including('UPLOADCARE_STORE' => '1')
        )
        .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })

      client.start(filename, size, 'application/octet-stream', store: 1)
    end
  end

  describe '#complete' do
    let(:uuid) { 'upload-uuid-123' }
    let(:mock_response) { { 'uuid' => uuid, 'file' => 'file-uuid-456' } }

    it 'completes multipart upload' do
      stub_request(:post, 'https://upload.uploadcare.com/multipart/complete/')
        .with(
          body: hash_including('uuid' => uuid, 'pub_key' => 'test_public_key')
        )
        .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.complete(uuid)
      expect(result).to eq(mock_response)
    end
  end

  describe '#upload_chunk' do
    let(:file_path) { File.join(File.dirname(__FILE__), '../../fixtures/big.jpeg') }
    let(:upload_data) do
      {
        'parts' => [
          {
            'url' => 'https://s3.amazonaws.com/bucket/part1',
            'start_offset' => 0,
            'end_offset' => 1000
          }
        ]
      }
    end

    it 'uploads chunks to S3' do
      stub_request(:put, 'https://s3.amazonaws.com/bucket/part1')
        .with(
          headers: { 'Content-Type' => 'application/octet-stream' }
        )
        .to_return(status: 200)

      expect { client.upload_chunk(file_path, upload_data) }.not_to raise_error
    end

    it 'raises error on failed chunk upload' do
      stub_request(:put, 'https://s3.amazonaws.com/bucket/part1')
        .to_return(status: 403)

      expect { client.upload_chunk(file_path, upload_data) }
        .to raise_error(Uploadcare::RequestError, /Failed to upload chunk: 403/)
    end
  end

  describe '#upload_file' do
    let(:file_path) { File.join(File.dirname(__FILE__), '../../fixtures/big.jpeg') }
    let(:file_size) { File.size(file_path) }
    let(:start_response) do
      {
        'uuid' => 'upload-uuid-123',
        'parts' => [
          {
            'url' => 'https://s3.amazonaws.com/bucket/part1',
            'start_offset' => 0,
            'end_offset' => file_size
          }
        ]
      }
    end
    let(:complete_response) { { 'uuid' => 'upload-uuid-123', 'file' => 'file-uuid-456' } }

    it 'performs full multipart upload flow' do
      # Stub start request
      stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
        .to_return(status: 200, body: start_response.to_json, headers: { 'Content-Type' => 'application/json' })

      # Stub S3 upload
      stub_request(:put, 'https://s3.amazonaws.com/bucket/part1')
        .to_return(status: 200)

      # Stub complete request
      stub_request(:post, 'https://upload.uploadcare.com/multipart/complete/')
        .to_return(status: 200, body: complete_response.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.upload_file(file_path)
      expect(result).to eq(complete_response)
    end

    it 'uses custom filename if provided' do
      stub_request(:post, 'https://upload.uploadcare.com/multipart/start/')
        .with(
          body: hash_including('filename' => 'custom_name.jpg')
        )
        .to_return(status: 200, body: start_response.to_json, headers: { 'Content-Type' => 'application/json' })

      stub_request(:put, 'https://s3.amazonaws.com/bucket/part1')
        .to_return(status: 200)

      stub_request(:post, 'https://upload.uploadcare.com/multipart/complete/')
        .to_return(status: 200, body: complete_response.to_json, headers: { 'Content-Type' => 'application/json' })

      client.upload_file(file_path, filename: 'custom_name.jpg')
    end
  end

  describe 'CHUNK_SIZE constant' do
    it 'is set to 5MB' do
      expect(described_class::CHUNK_SIZE).to eq(5 * 1024 * 1024)
    end
  end
end