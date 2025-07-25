# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Uploader do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'test_public_key',
      secret_key: 'test_secret_key'
    )
  end

  describe '.upload' do
    context 'with a file path' do
      let(:file_path) { File.join(File.dirname(__FILE__), '../../fixtures/kitten.jpeg') }
      let(:mock_response) { { 'file' => 'file-uuid-123' } }

      it 'uploads a file' do
        allow_any_instance_of(Uploadcare::UploaderClient).to receive(:upload_file).and_return(mock_response)
        
        result = described_class.upload(file_path, {}, config)
        expect(result).to be_a(Uploadcare::File)
        expect(result.uuid).to eq('file-uuid-123')
      end
    end

    context 'with a URL' do
      let(:url) { 'https://example.com/image.jpg' }
      let(:mock_response) { { 'file' => 'file-uuid-123' } }

      it 'uploads from URL' do
        allow_any_instance_of(Uploadcare::UploaderClient).to receive(:upload_from_url).and_return(mock_response)
        
        result = described_class.upload(url, {}, config)
        expect(result).to be_a(Uploadcare::File)
        expect(result.uuid).to eq('file-uuid-123')
      end
    end

    context 'with an array of files' do
      let(:files) { ['file1.jpg', 'file2.jpg'] }
      let(:mock_response) { { 'file' => 'file-uuid-123' } }

      it 'uploads multiple files' do
        allow_any_instance_of(Uploadcare::UploaderClient).to receive(:upload_file).and_return(mock_response)
        
        results = described_class.upload(files, {}, config)
        expect(results).to be_an(Array)
        expect(results.size).to eq(2)
        expect(results.first).to be_a(Uploadcare::File)
      end
    end
  end

  describe '.upload_file' do
    let(:file_path) { File.join(File.dirname(__FILE__), '../../fixtures/kitten.jpeg') }

    context 'with small file' do
      let(:mock_response) { { 'file' => 'file-uuid-123' } }

      it 'uses regular upload' do
        allow(File).to receive(:size).with(file_path).and_return(5 * 1024 * 1024) # 5MB
        
        uploader_client = instance_double(Uploadcare::UploaderClient)
        expect(Uploadcare::UploaderClient).to receive(:new).and_return(uploader_client)
        expect(uploader_client).to receive(:upload_file).with(file_path, {}).and_return(mock_response)
        
        result = described_class.upload_file(file_path, {}, config)
        expect(result).to be_a(Uploadcare::File)
        expect(result.uuid).to eq('file-uuid-123')
      end
    end

    context 'with large file' do
      let(:mock_response) { { 'file' => 'file-uuid-456' } }

      it 'uses multipart upload' do
        allow(File).to receive(:size).with(file_path).and_return(15 * 1024 * 1024) # 15MB
        
        multipart_client = instance_double(Uploadcare::MultipartUploadClient)
        expect(Uploadcare::MultipartUploadClient).to receive(:new).and_return(multipart_client)
        expect(multipart_client).to receive(:upload_file).with(file_path, {}).and_return(mock_response)
        
        result = described_class.upload_file(file_path, {}, config)
        expect(result).to be_a(Uploadcare::File)
        expect(result.uuid).to eq('file-uuid-456')
      end
    end

    context 'with File object' do
      let(:file) { File.open(file_path) }
      let(:mock_response) { { 'file' => 'file-uuid-123' } }

      after { file.close }

      it 'extracts path from File object' do
        allow(File).to receive(:size).with(file_path).and_return(5 * 1024 * 1024)
        allow_any_instance_of(Uploadcare::UploaderClient).to receive(:upload_file).and_return(mock_response)
        
        result = described_class.upload_file(file, {}, config)
        expect(result).to be_a(Uploadcare::File)
      end
    end
  end

  describe '.upload_files' do
    let(:files) { ['file1.jpg', 'file2.jpg'] }
    let(:mock_response) { { 'file' => 'file-uuid-123' } }

    it 'uploads multiple files' do
      allow(described_class).to receive(:upload_file).and_return(Uploadcare::File.new({ 'uuid' => 'file-uuid-123' }, config))
      
      results = described_class.upload_files(files, {}, config)
      expect(results).to be_an(Array)
      expect(results.size).to eq(2)
      expect(results.all? { |r| r.is_a?(Uploadcare::File) }).to be true
    end
  end

  describe '.upload_from_url' do
    let(:url) { 'https://example.com/image.jpg' }

    context 'synchronous upload' do
      let(:mock_response) { { 'file' => 'file-uuid-123' } }

      it 'returns uploaded file' do
        uploader_client = instance_double(Uploadcare::UploaderClient)
        expect(Uploadcare::UploaderClient).to receive(:new).and_return(uploader_client)
        expect(uploader_client).to receive(:upload_from_url).with(url, {}).and_return(mock_response)
        
        result = described_class.upload_from_url(url, {}, config)
        expect(result).to be_a(Uploadcare::File)
        expect(result.uuid).to eq('file-uuid-123')
      end
    end

    context 'asynchronous upload' do
      let(:mock_response) { { 'token' => 'upload-token-123' } }

      it 'returns token info with status checker' do
        uploader_client = instance_double(Uploadcare::UploaderClient)
        expect(Uploadcare::UploaderClient).to receive(:new).and_return(uploader_client)
        expect(uploader_client).to receive(:upload_from_url).with(url, {}).and_return(mock_response)
        
        result = described_class.upload_from_url(url, {}, config)
        expect(result).to be_a(Hash)
        expect(result[:token]).to eq('upload-token-123')
        expect(result[:status]).to eq('pending')
        expect(result[:check_status]).to respond_to(:call)
      end
    end
  end

  describe '.check_upload_status' do
    let(:token) { 'upload-token-123' }
    let(:uploader_client) { instance_double(Uploadcare::UploaderClient) }

    before do
      expect(Uploadcare::UploaderClient).to receive(:new).and_return(uploader_client)
    end

    context 'when upload succeeds' do
      let(:mock_response) do
        { 'status' => 'success', 'file' => 'file-uuid-123' }
      end

      it 'returns uploaded file' do
        expect(uploader_client).to receive(:check_upload_status).with(token).and_return(mock_response)
        
        result = described_class.check_upload_status(token, config)
        expect(result).to be_a(Uploadcare::File)
        expect(result.uuid).to eq('file-uuid-123')
      end
    end

    context 'when upload fails' do
      let(:mock_response) do
        { 'status' => 'error', 'error' => 'Upload failed' }
      end

      it 'raises error' do
        expect(uploader_client).to receive(:check_upload_status).with(token).and_return(mock_response)
        
        expect { described_class.check_upload_status(token, config) }
          .to raise_error(Uploadcare::RequestError, 'Upload failed')
      end
    end

    context 'when upload is pending' do
      let(:mock_response) do
        { 'status' => 'pending', 'done' => 50, 'total' => 100 }
      end

      it 'returns status info' do
        expect(uploader_client).to receive(:check_upload_status).with(token).and_return(mock_response)
        
        result = described_class.check_upload_status(token, config)
        expect(result).to eq(mock_response)
      end
    end
  end

  describe '.file_info' do
    let(:uuid) { 'file-uuid-123' }
    let(:mock_response) { { 'uuid' => uuid, 'size' => 12345 } }

    it 'retrieves file info without storing' do
      uploader_client = instance_double(Uploadcare::UploaderClient)
      expect(Uploadcare::UploaderClient).to receive(:new).and_return(uploader_client)
      expect(uploader_client).to receive(:file_info).with(uuid).and_return(mock_response)
      
      result = described_class.file_info(uuid, config)
      expect(result).to eq(mock_response)
    end
  end
end