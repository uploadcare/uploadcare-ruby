# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::UploaderClient do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'test_public_key',
      secret_key: 'test_secret_key'
    )
  end

  subject(:client) { described_class.new(config) }

  describe '#upload_file' do
    let(:file_path) { File.join(File.dirname(__FILE__), '../../fixtures/kitten.jpeg') }
    let(:mock_response) { { 'file' => 'file-uuid-123' } }

    it 'uploads a file successfully' do
      stub_request(:post, 'https://upload.uploadcare.com/base/')
        .with(
          body: /Content-Disposition: form-data/,
          headers: { 'User-Agent' => /Uploadcare Ruby/ }
        )
        .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.upload_file(file_path)
      expect(result).to eq(mock_response)
    end

    it 'includes upload options in request' do
      stub_request(:post, 'https://upload.uploadcare.com/base/')
        .with do |request|
          request.body.include?('store') &&
            request.body.include?('1') &&
            request.body.include?('filename') &&
            request.body.include?('test.jpg')
        end
        .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })

      client.upload_file(file_path, store: 1, filename: 'test.jpg')
    end

    it 'includes metadata in request' do
      stub_request(:post, 'https://upload.uploadcare.com/base/')
        .with do |request|
          request.body.include?('metadata[key1]') &&
            request.body.include?('value1')
        end
        .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })

      client.upload_file(file_path, metadata: { key1: 'value1' })
    end
  end

  describe '#upload_files' do
    let(:file_paths) do
      [
        File.join(File.dirname(__FILE__), '../../fixtures/kitten.jpeg'),
        File.join(File.dirname(__FILE__), '../../fixtures/another_kitten.jpeg')
      ]
    end

    it 'uploads multiple files' do
      stub_request(:post, 'https://upload.uploadcare.com/base/')
        .to_return(status: 200, body: { 'file' => 'file-uuid-123' }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.upload_files(file_paths)
      expect(result[:files]).to be_an(Array)
      expect(result[:files].size).to eq(2)
    end
  end

  describe '#upload_from_url' do
    let(:url) { 'https://example.com/image.jpg' }

    context 'synchronous upload' do
      let(:mock_response) { { 'file' => 'file-uuid-123' } }

      it 'uploads from URL successfully' do
        stub_request(:post, 'https://upload.uploadcare.com/from_url/')
          .with(
            body: hash_including('source_url' => url, 'pub_key' => 'test_public_key')
          )
          .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })

        result = client.upload_from_url(url)
        expect(result).to eq(mock_response)
      end
    end

    context 'asynchronous upload' do
      let(:mock_response) { { 'token' => 'upload-token-123' } }

      it 'returns upload token for async upload' do
        stub_request(:post, 'https://upload.uploadcare.com/from_url/')
          .with(
            body: hash_including('source_url' => url)
          )
          .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })

        result = client.upload_from_url(url)
        expect(result['token']).to eq('upload-token-123')
      end
    end

    it 'includes options in request' do
      stub_request(:post, 'https://upload.uploadcare.com/from_url/')
        .with(
          body: hash_including(
            'source_url' => url,
            'check_URL_duplicates' => '1',
            'save_URL_duplicates' => '0'
          )
        )
        .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.upload_from_url(url, check_duplicates: 1, save_duplicates: 0)
    end
  end

  describe '#check_upload_status' do
    let(:token) { 'upload-token-123' }

    it 'checks upload status' do
      stub_request(:get, 'https://upload.uploadcare.com/from_url/status/')
        .with(query: hash_including('token' => token))
        .to_return(
          status: 200,
          body: { 'status' => 'success', 'file' => 'file-uuid-123' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = client.check_upload_status(token)
      expect(result['status']).to eq('success')
      expect(result['file']).to eq('file-uuid-123')
    end
  end

  describe '#file_info' do
    let(:uuid) { 'file-uuid-123' }

    it 'retrieves file info' do
      stub_request(:get, 'https://upload.uploadcare.com/info/')
        .with(query: hash_including('file_id' => uuid))
        .to_return(
          status: 200,
          body: { 'uuid' => uuid, 'size' => 12_345 }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = client.file_info(uuid)
      expect(result['uuid']).to eq(uuid)
      expect(result['size']).to eq(12_345)
    end
  end

  describe '#build_upload_params' do
    it 'builds correct parameters' do
      options = {
        store: 1,
        filename: 'test.jpg',
        check_duplicates: true,
        save_duplicates: false,
        metadata: { key1: 'value1', key2: 'value2' }
      }

      params = client.send(:build_upload_params, options)

      expect(params[:store]).to eq(1)
      expect(params[:filename]).to eq('test.jpg')
      expect(params[:check_URL_duplicates]).to eq(true)
      expect(params[:save_URL_duplicates]).to eq(false)
      expect(params['metadata[key1]']).to eq('value1')
      expect(params['metadata[key2]']).to eq('value2')
    end
  end
end
