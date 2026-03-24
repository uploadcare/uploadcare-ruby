# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api::Upload do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end

  subject(:upload) { described_class.new(config: config) }

  describe '#initialize' do
    it 'stores the config' do
      expect(upload.config).to eq(config)
    end

    it 'creates a Faraday connection to the upload API root' do
      expect(upload.connection).to be_a(Faraday::Connection)
      expect(upload.connection.url_prefix.to_s).to eq('https://upload.uploadcare.com/')
    end

    it 'defaults to global configuration when no config is provided' do
      Uploadcare.configure do |c|
        c.public_key = 'globalpubkey'
        c.secret_key = 'globalseckey'
        c.auth_type = 'Uploadcare.Simple'
      end

      default_upload = described_class.new
      expect(default_upload.config.public_key).to eq('globalpubkey')
    end
  end

  describe '#get' do
    it 'returns a successful Result on 200' do
      stub_request(:get, 'https://upload.uploadcare.com/info/')
        .with(query: hash_including('pub_key' => 'demopublickey'))
        .to_return(
          status: 200,
          body: { uuid: 'file-uuid', filename: 'test.jpg' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = upload.get(
        path: 'info/',
        params: { 'pub_key' => 'demopublickey', 'file_id' => 'file-uuid' },
        headers: {},
        request_options: {}
      )

      expect(result).to be_a(Uploadcare::Result)
      expect(result).to be_success
    end

    it 'returns a failure Result on error' do
      stub_request(:get, 'https://upload.uploadcare.com/info/')
        .with(query: hash_including({}))
        .to_return(
          status: 404,
          body: { detail: 'Not found.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = upload.get(path: 'info/', params: { 'pub_key' => 'demopublickey' }, headers: {}, request_options: {})

      expect(result).to be_failure
    end
  end

  describe '#post' do
    it 'returns a successful Result on 200' do
      stub_request(:post, 'https://upload.uploadcare.com/base/')
        .to_return(
          status: 200,
          body: { 'test.jpg' => 'file-uuid-123' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = upload.post(
        path: 'base/',
        params: { 'UPLOADCARE_PUB_KEY' => 'demopublickey' },
        headers: {},
        request_options: {}
      )

      expect(result).to be_a(Uploadcare::Result)
      expect(result).to be_success
    end

    it 'returns a failure Result on error' do
      stub_request(:post, 'https://upload.uploadcare.com/base/')
        .to_return(
          status: 400,
          body: { detail: 'Bad request' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = upload.post(path: 'base/', params: {}, headers: {}, request_options: {})

      expect(result).to be_failure
    end
  end

  describe '#upload_part_to_url' do
    let(:presigned_url) { 'https://s3.amazonaws.com/bucket/part?signature=abc123' }

    it 'uploads binary data to the presigned URL via PUT' do
      stub_request(:put, presigned_url)
        .with(
          body: 'binary-data-here',
          headers: { 'Content-Type' => 'application/octet-stream' }
        )
        .to_return(status: 200, body: '', headers: {})

      result = upload.upload_part_to_url(presigned_url, 'binary-data-here')

      expect(result).to be true
    end

    it 'reads IO objects before uploading' do
      io = StringIO.new('io-binary-data')

      stub_request(:put, presigned_url)
        .with(
          body: 'io-binary-data',
          headers: { 'Content-Type' => 'application/octet-stream' }
        )
        .to_return(status: 200, body: '', headers: {})

      result = upload.upload_part_to_url(presigned_url, io)

      expect(result).to be true
    end

    it 'raises MultipartUploadError after max retries on non-2xx responses' do
      stub_request(:put, presigned_url)
        .to_return(status: 500, body: 'Internal Server Error', headers: {}) # force Zeitwerk to load upload_error.rb
      expect do
        upload.upload_part_to_url(presigned_url, 'data', max_retries: 1)
      end.to raise_error(Uploadcare::Exception::MultipartUploadError, /Failed to upload part/)
    end

    it 'retries on failure up to max_retries times' do
      call_count = 0
      stub_request(:put, presigned_url).to_return do |_request|
        call_count += 1
        if call_count < 2
          { status: 500, body: 'error' }
        else
          { status: 200, body: '' }
        end
      end

      result = upload.upload_part_to_url(presigned_url, 'data', max_retries: 3)

      expect(result).to be true
      expect(call_count).to eq(2)
    end

    it 'treats max_retries as the number of retries after the initial attempt' do
      call_count = 0

      stub_request(:put, presigned_url).to_return do |_request|
        call_count += 1
        { status: 500, body: 'error' }
      end

      expect do
        upload.upload_part_to_url(presigned_url, 'data', max_retries: 2)
      end.to raise_error(Uploadcare::Exception::MultipartUploadError, /Failed to upload part after 2 retries/)

      expect(call_count).to eq(3)
    end
  end

  describe 'endpoint accessors' do
    it 'returns a Files endpoint' do
      expect(upload.files).to be_a(Uploadcare::Api::Upload::Files)
    end

    it 'returns a Groups endpoint' do
      expect(upload.groups).to be_a(Uploadcare::Api::Upload::Groups)
    end

    it 'memoizes endpoint instances' do
      files = upload.files
      groups = upload.groups

      expect(upload.files).to be(files)
      expect(upload.groups).to be(groups)
    end
  end

  describe 'request options' do
    it 'applies timeout from request_options' do
      stub_request(:get, 'https://upload.uploadcare.com/info/')
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: { uuid: 'test' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = upload.get(
        path: 'info/',
        params: { 'pub_key' => 'demopublickey' },
        headers: {},
        request_options: { timeout: 30, open_timeout: 10 }
      )

      expect(result).to be_success
    end
  end
end
