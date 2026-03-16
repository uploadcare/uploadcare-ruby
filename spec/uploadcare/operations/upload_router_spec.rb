# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Uploadcare::Operations::UploadRouter do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple',
      multipart_size_threshold: 100 * 1024 * 1024
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:upload_api) { instance_double(Uploadcare::Api::Upload) }
  let(:upload_files_api) { double('upload_files') }
  let(:api) { instance_double(Uploadcare::Client::Api, upload: upload_api) }
  let(:router) { described_class.new(client: client) }

  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

  before do
    allow(client).to receive(:api).and_return(api)
    allow(upload_api).to receive(:files).and_return(upload_files_api)
  end

  describe '#initialize' do
    it 'stores client reference' do
      expect(router.client).to eq(client)
    end
  end

  describe '#upload' do
    context 'with a small file' do
      it 'routes to upload_file for small File objects' do
        tempfile = Tempfile.new('small')
        tempfile.write('x' * 1024)
        tempfile.rewind

        allow(upload_files_api).to receive(:direct_many)
          .with(files: [tempfile], request_options: {})
          .and_return(Uploadcare::Result.success({ 'small.txt' => file_uuid }))

        result = router.upload(tempfile)
        expect(result).to be_a(Uploadcare::Resources::File)
        expect(result.uuid).to eq(file_uuid)

        tempfile.close!
      end
    end

    context 'with a string URL' do
      it 'routes to upload_from_url' do
        url = 'https://example.com/photo.jpg'
        response = { 'uuid' => file_uuid, 'original_filename' => 'photo.jpg' }

        allow(upload_files_api).to receive(:from_url)
          .with(source_url: url, request_options: {})
          .and_return(Uploadcare::Result.success(response))

        result = router.upload(url)
        expect(result).to be_a(Uploadcare::Resources::File)
      end
    end

    context 'with an array of files' do
      it 'routes to upload_files' do
        file1 = Tempfile.new('f1')
        file2 = Tempfile.new('f2')
        file1.write('data1')
        file2.write('data2')
        file1.rewind
        file2.rewind

        allow(upload_files_api).to receive(:direct_many)
          .and_return(Uploadcare::Result.success({ 'f1' => 'uuid-1', 'f2' => 'uuid-2' }))

        result = router.upload([file1, file2])
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        result.each { |f| expect(f).to be_a(Uploadcare::Resources::File) }

        file1.close!
        file2.close!
      end
    end

    context 'with an unsupported type' do
      it 'raises ArgumentError' do
        expect {
          router.upload(12345)
        }.to raise_error(ArgumentError, /Expected input to be a File\/Array\/URL/)
      end
    end
  end

  describe '#upload_file' do
    it 'uploads a single file directly' do
      tempfile = Tempfile.new('upload')
      tempfile.write('content')
      tempfile.rewind

      allow(upload_files_api).to receive(:direct_many)
        .with(files: [tempfile], request_options: {}, store: true)
        .and_return(Uploadcare::Result.success({ 'upload.txt' => file_uuid }))

      result = router.upload_file(file: tempfile, store: true)
      expect(result).to be_a(Uploadcare::Resources::File)
      expect(result.uuid).to eq(file_uuid)
      expect(result.original_filename).to eq('upload.txt')

      tempfile.close!
    end
  end

  describe '#upload_files' do
    it 'uploads multiple files directly' do
      f1 = Tempfile.new('a')
      f2 = Tempfile.new('b')

      allow(upload_files_api).to receive(:direct_many)
        .with(files: [f1, f2], request_options: {})
        .and_return(Uploadcare::Result.success({ 'a.txt' => 'uuid-a', 'b.txt' => 'uuid-b' }))

      result = router.upload_files(files: [f1, f2])
      expect(result.length).to eq(2)
      expect(result.map(&:uuid)).to contain_exactly('uuid-a', 'uuid-b')

      f1.close!
      f2.close!
    end
  end

  describe '#upload_from_url' do
    it 'uploads from URL and returns a File resource' do
      url = 'https://example.com/image.png'
      response = { 'uuid' => file_uuid }

      allow(upload_files_api).to receive(:from_url)
        .with(source_url: url, request_options: {})
        .and_return(Uploadcare::Result.success(response))

      result = router.upload_from_url(url: url)
      expect(result).to be_a(Uploadcare::Resources::File)
      expect(result.uuid).to eq(file_uuid)
    end

    it 'returns raw response when async option is true' do
      url = 'https://example.com/image.png'
      response = { 'token' => 'upload-token-123', 'type' => 'token' }

      allow(upload_files_api).to receive(:from_url)
        .with(source_url: url, request_options: {}, async: true)
        .and_return(Uploadcare::Result.success(response))

      result = router.upload_from_url(url: url, async: true)
      expect(result).to be_a(Hash)
      expect(result['token']).to eq('upload-token-123')
    end
  end

  describe '#multipart_upload' do
    it 'delegates to MultipartUpload and returns a File resource' do
      tempfile = Tempfile.new('large')
      tempfile.write('x' * 1024)
      tempfile.rewind

      multipart = instance_double(Uploadcare::Operations::MultipartUpload)
      allow(Uploadcare::Operations::MultipartUpload).to receive(:new)
        .with(upload_client: upload_api, config: client.config)
        .and_return(multipart)

      allow(multipart).to receive(:upload)
        .and_return(Uploadcare::Result.success({ 'uuid' => file_uuid }))

      result = router.multipart_upload(file: tempfile)
      expect(result).to be_a(Uploadcare::Resources::File)
      expect(result.uuid).to eq(file_uuid)

      tempfile.close!
    end

    it 'returns raw response when result is not a hash with uuid' do
      tempfile = Tempfile.new('large')
      tempfile.write('x' * 1024)
      tempfile.rewind

      multipart = instance_double(Uploadcare::Operations::MultipartUpload)
      allow(Uploadcare::Operations::MultipartUpload).to receive(:new).and_return(multipart)
      allow(multipart).to receive(:upload).and_return(Uploadcare::Result.success('unexpected'))

      result = router.multipart_upload(file: tempfile)
      expect(result).to eq('unexpected')

      tempfile.close!
    end
  end

  describe '#upload_from_url_status' do
    it 'returns upload status' do
      allow(upload_files_api).to receive(:from_url_status)
        .with(token: 'upload-token', request_options: {})
        .and_return(Uploadcare::Result.success({ 'status' => 'progress', 'done' => 50, 'total' => 100 }))

      result = router.upload_from_url_status(token: 'upload-token')
      expect(result['status']).to eq('progress')
    end
  end

  describe '#file_info' do
    it 'returns file info from upload API' do
      allow(upload_files_api).to receive(:info)
        .with(file_id: file_uuid, request_options: {})
        .and_return(Uploadcare::Result.success({ 'uuid' => file_uuid, 'is_ready' => true }))

      result = router.file_info(file_id: file_uuid)
      expect(result['uuid']).to eq(file_uuid)
    end
  end
end
