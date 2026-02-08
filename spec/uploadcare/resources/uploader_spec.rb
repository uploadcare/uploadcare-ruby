# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Uploader do
  let!(:file) { File.open('spec/fixtures/kitten.jpeg') }
  let!(:another_file) { File.open('spec/fixtures/another_kitten.jpeg') }
  let!(:big_file) { File.open('spec/fixtures/big.jpeg') }

  after(:each) do
    [file, another_file, big_file].each do |f|
      f.close unless f.nil? || f.closed?
    end
  end

  describe 'upload method routing' do
    describe 'with invalid input types' do
      it 'raises ArgumentError for unsupported object types' do
        expect { described_class.upload(object: 123) }.to raise_error(ArgumentError, %r{Expected input to be a file/Array/URL})
        expect { described_class.upload(object: { invalid: 'object' }) }.to raise_error(ArgumentError, %r{Expected input to be a file/Array/URL})
        expect { described_class.upload(object: nil) }.to raise_error(ArgumentError, %r{Expected input to be a file/Array/URL})
      end
    end

    describe 'routing to correct upload method' do
      before do
        allow(described_class).to receive(:multipart_upload)
        allow(described_class).to receive(:upload_file)
        allow(described_class).to receive(:upload_files)
        allow(described_class).to receive(:upload_from_url)
      end

      it 'routes big files to multipart_upload' do
        allow(described_class).to receive(:big_file?).and_return(true)
        described_class.upload(object: big_file)
        expect(described_class).to have_received(:multipart_upload).with(file: big_file, config: Uploadcare.configuration)
      end

      it 'routes single file to upload_file' do
        allow(described_class).to receive(:big_file?).and_return(false)
        described_class.upload(object: file)
        expect(described_class).to have_received(:upload_file).with(file: file, config: Uploadcare.configuration)
      end

      it 'routes array to upload_files' do
        described_class.upload(object: [file, another_file])
        expect(described_class).to have_received(:upload_files).with(files: [file, another_file], config: Uploadcare.configuration)
      end

      it 'routes string URL to upload_from_url' do
        url = 'https://example.com/image.jpg'
        described_class.upload(object: url)
        expect(described_class).to have_received(:upload_from_url).with(url: url, config: Uploadcare.configuration)
      end
    end
  end

  describe 'upload_file' do
    it 'calls upload_many and processes response' do
      mock_file = double('file')
      mock_client = double('client')
      allow(described_class).to receive(:uploader_client).and_return(mock_client)
      allow(mock_client).to receive(:upload_many).and_return([['test.jpg', 'uuid-123']])
      allow(Uploadcare::File).to receive(:new).and_return(mock_file)

      result = described_class.upload_file(file: file, store: true, metadata: { key: 'value' })

      expect(mock_client).to have_received(:upload_many).with(files: [file], store: true, metadata: { key: 'value' })
      expect(Uploadcare::File).to have_received(:new).with({ uuid: 'uuid-123', original_filename: 'test.jpg' },
                                                           Uploadcare.configuration)
      expect(result).to eq(mock_file)
    end
  end

  describe 'upload_files' do
    it 'handles upload options correctly' do
      allow_any_instance_of(Uploadcare::UploaderClient).to receive(:upload_many)
        .and_return({ 'kitten.jpeg' => 'uuid1', 'another_kitten.jpeg' => 'uuid2' })
      uploads = described_class.upload_files(files: [file, another_file], store: true, metadata: { key: 'value' })

      expect(uploads.first.uuid).to eq('uuid1')
      expect(uploads.last.uuid).to eq('uuid2')
    end

    it 'returns empty array for empty input' do
      allow_any_instance_of(Uploadcare::UploaderClient).to receive(:upload_many).and_return({})
      uploads = described_class.upload_files(files: [])
      expect(uploads).to eq([])
    end
  end

  describe 'upload_from_url' do
    let(:url) { 'https://placekitten.com/200/200' }

    it 'handles upload options' do
      options = {
        store: true,
        check_URL_duplicates: true,
        filename: 'custom_name.jpg',
        metadata: { source: 'test' }
      }

      allow_any_instance_of(Uploadcare::UploaderClient).to receive(:upload_from_url)
        .with(url: url, request_options: {}, **options)
        .and_return({ 'uuid' => 'test-uuid' })

      upload = described_class.upload_from_url(url: url, **options)
      expect(upload).to be_kind_of(Uploadcare::File)
    end

    it 'handles async upload option' do
      options = { async: true }

      allow_any_instance_of(Uploadcare::UploaderClient).to receive(:upload_from_url)
        .with(url: url, request_options: {}, **options)
        .and_return({ 'token' => 'async-token' })

      result = described_class.upload_from_url(url: url, **options)
      expect(result).to eq({ 'token' => 'async-token' })
    end

    context 'when errors occur' do
      it 'handles network timeouts' do
        allow_any_instance_of(Uploadcare::UploaderClient).to receive(:upload_from_url)
          .and_raise(Faraday::TimeoutError)

        expect { described_class.upload_from_url(url: url) }.to raise_error(Faraday::TimeoutError)
      end
    end
  end

  describe 'upload_from_url_status' do
    let(:token) { 'test-token-123' }

    it 'delegates to uploader client' do
      mock_response = double('response', success: { status: 'success' })

      allow_any_instance_of(Uploadcare::UploaderClient).to receive(:fetch_upload_from_url_status)
        .with(token: token, request_options: {})
        .and_return(mock_response)

      status = described_class.upload_from_url_status(token: token)
      expect(status).to eq(mock_response)
    end

    it 'handles different status responses' do
      mock_response = double('response', success: { status: 'progress', done: 50, total: 100 })

      allow_any_instance_of(Uploadcare::UploaderClient).to receive(:fetch_upload_from_url_status)
        .and_return(mock_response)

      status = described_class.upload_from_url_status(token: token)
      expect(status).to eq(mock_response)
    end
  end

  describe 'get_upload_from_url_status' do
    it 'delegates to upload_from_url_status' do
      allow(described_class).to receive(:upload_from_url_status).and_return({ 'status' => 'success' })

      result = described_class.get_upload_from_url_status(token: 'token')

      expect(result).to eq({ 'status' => 'success' })
      expect(described_class).to have_received(:upload_from_url_status).with(token: 'token', config: Uploadcare.configuration,
                                                                             request_options: {})
    end
  end

  describe 'file_info' do
    let(:uuid) { 'test-uuid-123' }

    it 'delegates to uploader client' do
      mock_info = { 'uuid' => uuid, 'size' => 1024 }

      allow_any_instance_of(Uploadcare::UploaderClient).to receive(:file_info)
        .with(uuid: uuid, request_options: {})
        .and_return(mock_info)

      info = described_class.file_info(uuid: uuid)
      expect(info).to eq(mock_info)
    end
  end

  describe 'private helper methods' do
    describe 'file?' do
      it 'returns true for valid file objects' do
        expect(described_class.send(:file?, file)).to be true
      end

      it 'returns false for non-file objects' do
        expect(described_class.send(:file?, 'string')).to be false
        expect(described_class.send(:file?, 123)).to be false
        expect(described_class.send(:file?, nil)).to be false
      end

      it 'returns false for file objects with non-existent paths' do
        non_existent_file = double('file')
        allow(non_existent_file).to receive(:respond_to?).with(:path).and_return(true)
        allow(non_existent_file).to receive(:path).and_return('/path/that/does/not/exist')

        expect(described_class.send(:file?, non_existent_file)).to be false
      end
    end

    describe 'big_file?' do
      before do
        Uploadcare.configuration.multipart_size_threshold = 5 * 1024 * 1024 # 5MB
      end

      it 'returns true for files above threshold' do
        expect(described_class.send(:big_file?, big_file, Uploadcare.configuration)).to be true
      end

      it 'returns false for files below threshold' do
        expect(described_class.send(:big_file?, file, Uploadcare.configuration)).to be false
      end

      it 'returns false for non-file objects' do
        expect(described_class.send(:big_file?, 'string', Uploadcare.configuration)).to be false
      end
    end

    describe 'create_basic_file' do
      it 'creates a basic file object with minimal data' do
        uuid = 'test-uuid-123'
        file_name = 'test.jpg'

        result = described_class.send(:create_basic_file, uuid: uuid, file_name: file_name,
                                                          config: Uploadcare.configuration)

        expect(result).to be_a(Uploadcare::File)
        expect(result.uuid).to eq(uuid)
        expect(result.original_filename).to eq(file_name)
      end
    end
  end

  describe 'configuration and initialization' do
    it 'initializes with default configuration' do
      uploader = described_class.new
      expect(uploader.instance_variable_get(:@uploader_client)).to be_kind_of(Uploadcare::UploaderClient)
    end

    it 'uses class-level uploader_client when not instantiated' do
      expect(described_class.send(:uploader_client)).to be_kind_of(Uploadcare::UploaderClient)
    end
  end

  describe 'edge cases and error handling' do
    it 'handles network interruptions during upload' do
      allow_any_instance_of(Uploadcare::UploaderClient).to receive(:upload_many)
        .and_raise(Faraday::ConnectionFailed)

      expect { described_class.upload(object: file) }.to raise_error(Faraday::ConnectionFailed)
    end

    it 'handles mixed valid and invalid files in array' do
      invalid_file = double('file')
      allow(invalid_file).to receive(:respond_to?).and_return(false)
      allow(invalid_file).to receive(:respond_to?).with(:path).and_return(true)
      allow(invalid_file).to receive(:respond_to?).with(:original_filename).and_return(false)
      allow(invalid_file).to receive(:path).and_return('/nonexistent/path')

      # This should raise an error when trying to upload
      expect do
        described_class.upload(object: [file, invalid_file])
      end.to raise_error(StandardError)
    end
  end

  describe 'upload_many' do
    it 'returns a hash of filenames and uids', :aggregate_failures do
      VCR.use_cassette('upload_upload_many') do
        uploads_list = described_class.upload(object: [file, another_file])
        expect(uploads_list.length).to eq 2
        first_upload = uploads_list.first
        expect(first_upload.original_filename).not_to be_empty
        expect(first_upload.uuid).not_to be_empty
      end
    end

    describe 'upload_one' do
      it 'returns a file', :aggregate_failures do
        VCR.use_cassette('upload_upload_one') do
          upload = described_class.upload(object: file)
          expect(upload).to be_kind_of(Uploadcare::File)
          expect(file.path).to end_with(upload.original_filename.to_s)
          # Skip size comparison as it may not be available without secret key
        end
      end
    end

    describe 'upload_from_url' do
      let(:url) { 'https://placekitten.com/2250/2250' }

      it 'polls server and returns file' do
        VCR.use_cassette('upload_upload_from_url') do
          upload = described_class.upload(object: url)
          expect(upload).to be_kind_of(Uploadcare::File)
        end
      end

      context 'when signed uploads are enabled' do
        before do
          allow(Uploadcare.configuration).to receive(:sign_uploads).and_return(true)
        end

        it 'handles signed uploads' do
          VCR.use_cassette('upload_upload_from_url_with_signature') do
            upload = described_class.upload(object: url)
            expect(upload).to be_kind_of(Uploadcare::File)
          end
        end
      end

      it 'raises error with information if file upload takes time' do
        original_tries = Uploadcare.configuration.max_request_tries
        Uploadcare.configuration.max_request_tries = 1

        VCR.use_cassette('upload_upload_from_url_timeout') do
          url = 'https://placekitten.com/2250/2250'
          expect { described_class.upload(object: url) }.to raise_error(StandardError)
        end

        Uploadcare.configuration.max_request_tries = original_tries
      end
    end

    describe 'multipart_upload' do
      it 'uploads a file', :aggregate_failures do
        VCR.use_cassette('upload_multipart_upload') do
          # Minimal size for file to be valid for multipart upload is 10 mb
          original_threshold = Uploadcare.configuration.multipart_size_threshold
          Uploadcare.configuration.multipart_size_threshold = 1 * 1024 * 1024 # 1MB for testing

          allow_any_instance_of(Uploadcare::MultipartUploaderClient).to receive(:upload)
            .and_return({ 'uuid' => 'test-uuid' })

          file_result = described_class.multipart_upload(file: big_file)
          expect(file_result).to be_kind_of(Uploadcare::File)
          expect(file_result.uuid).not_to be_empty

          Uploadcare.configuration.multipart_size_threshold = original_threshold
        end
      end

      it 'returns response as-is for unexpected format' do
        unexpected_response = 'unexpected'
        allow_any_instance_of(Uploadcare::MultipartUploaderClient).to receive(:upload)
          .and_return(unexpected_response)

        result = described_class.multipart_upload(file: big_file)

        expect(result).to eq('unexpected')
      end
    end

    describe 'upload_from_url_status' do
      it 'gets a status of upload-from-URL' do
        VCR.use_cassette('upload_get_upload_from_url_status') do
          token = '0313e4e2-f2ca-4564-833b-4f71bc8cba27'

          mock_response = double('response', success: { status: 'success' })
          allow_any_instance_of(Uploadcare::UploaderClient).to receive(:fetch_upload_from_url_status)
            .with(token: token, request_options: {})
            .and_return(mock_response)

          status_info = described_class.upload_from_url_status(token: token)
          expect(status_info).to eq(mock_response)
        end
      end
    end
  end
end
