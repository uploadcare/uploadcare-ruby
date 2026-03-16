# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Uploadcare::Operations::MultipartUpload do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple',
      multipart_chunk_size: 5 * 1024 * 1024
    )
  end
  let(:upload_client) { instance_double(Uploadcare::Api::Upload) }
  let(:upload_files_api) { double('upload_files') }
  let(:uploader) { described_class.new(upload_client: upload_client, config: config) }

  before do
    allow(upload_client).to receive(:files).and_return(upload_files_api)
  end

  describe '#initialize' do
    it 'stores upload_client and config' do
      expect(uploader.upload_client).to eq(upload_client)
      expect(uploader.config).to eq(config)
    end
  end

  describe 'CHUNK_SIZE' do
    it 'equals 5MB' do
      expect(described_class::CHUNK_SIZE).to eq(5_242_880)
    end
  end

  describe '#upload' do
    let(:tempfile) do
      file = Tempfile.new(['multipart_test', '.bin'])
      file.write('x' * (10 * 1024))
      file.rewind
      file
    end

    let(:presigned_urls) { ['https://s3.example.com/part1', 'https://s3.example.com/part2'] }

    let(:start_response) do
      { 'uuid' => 'multipart-uuid-123', 'parts' => presigned_urls }
    end

    after do
      tempfile.close!
    end

    it 'raises ArgumentError when file lacks read/path methods' do
      result = uploader.upload(file: 'not-a-file')
      expect(result).to be_a(Uploadcare::Result)
      expect(result.failure?).to be true
      expect(result.error).to be_a(ArgumentError)
    end

    it 'completes the full multipart upload flow' do
      allow(upload_files_api).to receive(:multipart_start)
        .and_return(Uploadcare::Result.success(start_response))

      allow(upload_client).to receive(:upload_part_to_url)

      allow(upload_files_api).to receive(:multipart_complete)
        .with(uuid: 'multipart-uuid-123', request_options: {})
        .and_return(Uploadcare::Result.success({ 'uuid' => 'multipart-uuid-123' }))

      result = uploader.upload(file: tempfile)
      expect(result).to be_a(Uploadcare::Result)
      expect(result.success?).to be true
      expect(result.value).to eq({ 'uuid' => 'multipart-uuid-123' })
    end

    it 'reports progress via block callback' do
      allow(upload_files_api).to receive(:multipart_start)
        .and_return(Uploadcare::Result.success(start_response))
      allow(upload_client).to receive(:upload_part_to_url)
      allow(upload_files_api).to receive(:multipart_complete)
        .and_return(Uploadcare::Result.success({ 'uuid' => 'multipart-uuid-123' }))

      progress_calls = []
      uploader.upload(file: tempfile) do |progress|
        progress_calls << progress
      end

      expect(progress_calls).not_to be_empty
      progress_calls.each do |p|
        expect(p).to have_key(:uploaded)
        expect(p).to have_key(:total)
        expect(p).to have_key(:part)
        expect(p).to have_key(:total_parts)
      end
    end

    it 'uploads parts to presigned URLs' do
      allow(upload_files_api).to receive(:multipart_start)
        .and_return(Uploadcare::Result.success(start_response))
      allow(upload_files_api).to receive(:multipart_complete)
        .and_return(Uploadcare::Result.success({ 'uuid' => 'multipart-uuid-123' }))

      expect(upload_client).to receive(:upload_part_to_url).at_least(:once)

      uploader.upload(file: tempfile)
    end

    it 'passes content_type derived from file extension' do
      allow(upload_client).to receive(:upload_part_to_url)
      allow(upload_files_api).to receive(:multipart_complete)
        .and_return(Uploadcare::Result.success({ 'uuid' => 'multipart-uuid-123' }))

      expect(upload_files_api).to receive(:multipart_start) do |args|
        expect(args[:filename]).to be_a(String)
        expect(args[:size]).to be_a(Integer)
        expect(args[:content_type]).to be_a(String)
        Uploadcare::Result.success(start_response)
      end

      uploader.upload(file: tempfile)
    end
  end
end
