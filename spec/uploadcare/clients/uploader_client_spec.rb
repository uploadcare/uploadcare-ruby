# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::UploaderClient do
  subject { described_class.new }

  describe 'upload' do
    let(:file) { File.open('spec/fixtures/kitten.jpeg') }
    let(:another_file) { File.open('spec/fixtures/another_kitten.jpeg') }

    it 'uploads a file' do
      VCR.use_cassette('upload_upload') do
        response = subject.upload(file: file, metadata: { subsystem: 'test' })
        expect(response).to be_a(Uploadcare::Result)
        expect(response.success.keys.first).to include('.jpeg')
      end
    end

    it 'uploads multiple files in one request' do
      VCR.use_cassette('upload_upload_many') do
        response = subject.upload_many(files: [file, another_file])
        expect(response).to be_a(Uploadcare::Result)
        expect(response.success.size).to eq(2)
      end
    end
  end

  describe '#handle_polling_response' do
    it 'raises RequestError when status is error' do
      response = { 'status' => 'error', 'error' => 'Upload failed' }

      expect do
        subject.send(:handle_polling_response, response)
      end.to raise_error(Uploadcare::Exception::RequestError, /Upload failed/)
    end

    it 'raises RetryError when status is progress' do
      response = { 'status' => 'progress', 'error' => 'Still uploading' }

      expect do
        subject.send(:handle_polling_response, response)
      end.to raise_error(Uploadcare::Exception::RetryError, /Still uploading/)
    end

    it 'returns response when status is success' do
      response = { 'status' => 'success', 'file' => 'uuid' }

      result = subject.send(:handle_polling_response, response)
      expect(result).to eq(response)
    end
  end

  describe '#get_upload_from_url_status' do
    it 'delegates to upload_from_url_status' do
      allow_any_instance_of(described_class).to receive(:fetch_upload_from_url_status)
        .with(token: 'token', request_options: {})
        .and_return({ 'status' => 'success' })

      result = described_class.new.get_upload_from_url_status(token: 'token')

      expect(result).to be_a(Uploadcare::Result)
      expect(result.success).to eq({ 'status' => 'success' })
    end
  end
end
