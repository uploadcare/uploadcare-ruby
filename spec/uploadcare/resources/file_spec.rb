# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::File do
  let(:uuid) { SecureRandom.uuid }
  let(:response_body) do
    {
      datetime_removed: nil,
      datetime_stored: '2018-11-26T12:49:10.477888Z',
      datetime_uploaded: '2018-11-26T12:49:09.945335Z',
      variations: nil,
      is_image: true,
      is_ready: true,
      mime_type: 'image/jpeg',
      original_file_url: "https://ucarecdn.com/#{uuid}/file.jpg",
      original_filename: 'file.jpg',
      size: 642,
      url: "https://api.uploadcare.com/files/#{uuid}/",
      uuid: uuid
    }
  end
  subject(:file) { described_class.new(uuid: uuid) }

  describe '#list' do
    let(:response_body) do
      {
        'next' => nil,
        'previous' => nil,
        'per_page' => 10,
        'results' => [
          {
            'uuid' => 'file_uuid_1',
            'original_filename' => 'file1.jpg',
            'size' => 12_345,
            'datetime_uploaded' => '2023-10-01T12:00:00Z',
            'url' => 'https://ucarecdn.com/file_uuid_1/',
            'is_image' => true,
            'mime_type' => 'image/jpeg'
          },
          {
            'uuid' => 'file_uuid_2',
            'original_filename' => 'file2.png',
            'size' => 67_890,
            'datetime_uploaded' => '2023-10-02T12:00:00Z',
            'url' => 'https://ucarecdn.com/file_uuid_2/',
            'is_image' => true,
            'mime_type' => 'image/png'
          }
        ],
        'total' => 2
      }
    end
    subject { described_class.list }

    before do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:list)
        .with(params: {}, request_options: {})
        .and_return(response_body)
    end

    it { is_expected.to be_a(Uploadcare::PaginatedCollection) }
    it { expect(subject.resources.size).to eq(2) }

    it 'returns FileList containing File Resources' do
      first_file = subject.resources.first
      expect(first_file).to be_a(described_class)
      expect(first_file.uuid).to eq('file_uuid_1')
      expect(first_file.original_filename).to eq('file1.jpg')
      expect(first_file.size).to eq(12_345)
      expect(first_file.datetime_uploaded).to eq('2023-10-01T12:00:00Z')
      expect(first_file.url).to eq('https://ucarecdn.com/file_uuid_1/')
      expect(first_file.is_image).to be true
      expect(first_file.mime_type).to eq('image/jpeg')
    end
  end

  describe '#store' do
    subject { file.store }

    before do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:store)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)
    end

    it { is_expected.to be_a(Uploadcare::File) }
    it { expect(subject.uuid).to eq(uuid) }
  end

  describe '#delete' do
    subject { file.delete }

    before do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:delete)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)
    end

    it { is_expected.to be_a(Uploadcare::File) }
    it { expect(subject.uuid).to eq(uuid) }
  end

  describe '#info' do
    subject { file.info }

    before do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:info)
        .with(uuid: uuid, params: {}, request_options: {})
        .and_return(response_body)
    end

    it { is_expected.to be_a(Uploadcare::File) }
    it { expect(subject.uuid).to eq(uuid) }
  end

  describe 'Batch Operations' do
    let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid] }
    let(:file_data) { { 'uuid' => SecureRandom.uuid, 'original_filename' => 'file.jpg' } }
    let(:response_body) do
      {
        status: 200,
        result: [file_data],
        problems: [{ 'some-uuid': 'Missing in the project' }]
      }
    end

    describe '.batch_store' do
      subject { described_class.batch_store(uuids: uuids) }

      before do
        allow_any_instance_of(Uploadcare::FileClient).to receive(:batch_store)
          .with(uuids: uuids, request_options: {})
          .and_return(response_body)
      end

      it { is_expected.to be_a(Uploadcare::BatchFileResult) }
      it { expect(subject.status).to eq(200) }
      it { expect(subject.result.first).to be_a(Uploadcare::File) }
      it { expect(subject.problems).not_to be_empty }
    end

    describe '.batch_delete' do
      subject { described_class.batch_delete(uuids: uuids) }

      before do
        allow_any_instance_of(Uploadcare::FileClient).to receive(:batch_delete)
          .with(uuids: uuids, request_options: {})
          .and_return(response_body)
      end

      it { is_expected.to be_a(Uploadcare::BatchFileResult) }
      it { expect(subject.status).to eq(200) }
      it { expect(subject.result.first).to be_a(Uploadcare::File) }
      it { expect(subject.problems).not_to be_empty }
    end
  end

  describe '#local_copy' do
    let(:options) { { store: 'true', metadata: { key: 'value' } } }
    let(:source) { SecureRandom.uuid }
    let(:response_body) do
      {
        'type' => 'file',
        'result' => {
          'uuid' => source,
          'original_filename' => 'copy_of_file.jpg',
          'size' => 12_345,
          'datetime_uploaded' => '2023-10-10T12:00:00Z',
          'url' => "https://ucarecdn.com/#{source}/",
          'is_image' => true,
          'mime_type' => 'image/jpeg'
        }
      }
    end

    subject { file.local_copy(options: options) }

    before do
      file.uuid = source
      allow_any_instance_of(Uploadcare::FileClient).to receive(:local_copy)
        .with(source: source, options: options, request_options: {})
        .and_return(response_body)
    end

    it { is_expected.to be_a(Uploadcare::File) }

    it { expect(subject.uuid).to eq(source) }
    it { expect(subject.original_filename).to eq('copy_of_file.jpg') }
    it { expect(subject.size).to eq(12_345) }
  end

  describe '#remote_copy' do
    let(:source) { SecureRandom.uuid }
    let(:target) { 'custom_storage_name' }
    let(:s3_url) { 's3://mybucket/copied_file.jpg' }
    let(:options) { { make_public: false, pattern: '${default}' } }
    let(:response_body) { { 'type' => 'url', 'result' => s3_url } }

    subject { file.remote_copy(target: target, options: options) }

    before do
      file.uuid = source
      allow_any_instance_of(Uploadcare::FileClient).to receive(:remote_copy)
        .with(source: source, target: target, options: options, request_options: {})
        .and_return(response_body)
    end

    it { is_expected.to be_a(String) }
    it { is_expected.to eq(s3_url) }
  end

  describe '.local_copy' do
    let(:source) { SecureRandom.uuid }
    let(:options) { { store: 'true', metadata: { key: 'value' } } }
    let(:response_body) do
      {
        'type' => 'file',
        'result' => {
          'uuid' => source,
          'original_filename' => 'copy_of_file.jpg',
          'size' => 12_345,
          'datetime_uploaded' => '2023-10-10T12:00:00Z',
          'url' => "https://ucarecdn.com/#{source}/",
          'is_image' => true,
          'mime_type' => 'image/jpeg'
        }
      }
    end

    subject { described_class.local_copy(source: source, options: options) }

    before do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:local_copy)
        .with(source: source, options: options, request_options: {})
        .and_return(response_body)
    end

    it { is_expected.to be_a(Uploadcare::File) }

    it { expect(subject.uuid).to eq(source) }
    it { expect(subject.original_filename).to eq('copy_of_file.jpg') }
    it { expect(subject.size).to eq(12_345) }
  end

  describe '.remote_copy' do
    let(:source) { SecureRandom.uuid }
    let(:target) { 'custom_storage_name' }
    let(:s3_url) { 's3://mybucket/copied_file.jpg' }
    let(:options) { { make_public: false, pattern: '${default}' } }
    let(:response_body) { { 'type' => 'url', 'result' => s3_url } }

    subject { described_class.remote_copy(source: source, target: target, options: options) }

    before do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:remote_copy)
        .with(source: source, target: target, options: options, request_options: {})
        .and_return(response_body)
    end

    it { is_expected.to be_a(String) }
    it { is_expected.to eq(s3_url) }
  end

  describe '#convert_document' do
    let(:file) { described_class.new(uuid: uuid) }
    let(:params) { { format: 'pdf', page: '1' } }
    let(:conversion_result) do
      {
        'result' => [{ 'uuid' => 'converted-uuid-123' }]
      }
    end
    let(:converted_file_response) do
      {
        'uuid' => 'converted-uuid-123',
        'original_filename' => 'converted.pdf',
        'mime_type' => 'application/pdf'
      }
    end

    before do
      allow(Uploadcare::DocumentConverter).to receive(:convert_document)
        .and_return(conversion_result)
      allow(described_class).to receive(:info)
        .with(uuid: 'converted-uuid-123', config: Uploadcare.configuration, request_options: {})
        .and_return(described_class.new(converted_file_response))
    end

    it 'converts document and returns new file' do
      result = file.convert_document(params: params)

      expect(result).to be_a(described_class)
      expect(result.uuid).to eq('converted-uuid-123')
    end

    it 'raises ConversionError when params is not a hash' do
      expect do
        file.convert_document(params: 'invalid')
      end.to raise_error(Uploadcare::Exception::ConversionError, /The first argument must be a Hash/)
    end
  end

  describe '#convert_video' do
    let(:file) { described_class.new(uuid: uuid) }
    let(:params) { { format: 'mp4', quality: 'best' } }
    let(:conversion_result) do
      {
        'result' => [{ 'uuid' => 'converted-video-456' }]
      }
    end
    let(:converted_file_response) do
      {
        'uuid' => 'converted-video-456',
        'original_filename' => 'converted.mp4',
        'mime_type' => 'video/mp4'
      }
    end

    before do
      allow(Uploadcare::VideoConverter).to receive(:convert)
        .and_return(conversion_result)
      allow(described_class).to receive(:info)
        .with(uuid: 'converted-video-456', config: Uploadcare.configuration, request_options: {})
        .and_return(described_class.new(converted_file_response))
    end

    it 'converts video and returns new file' do
      result = file.convert_video(params: params)

      expect(result).to be_a(described_class)
      expect(result.uuid).to eq('converted-video-456')
    end
  end

  describe '#uuid' do
    context 'when uuid is already set' do
      let(:file) { described_class.new(uuid: 'test-uuid-123') }

      it 'returns the uuid' do
        expect(file.uuid).to eq('test-uuid-123')
      end
    end

    context 'when uuid is not set but url is' do
      let(:file) { described_class.new(url: 'https://ucarecdn.com/extracted-uuid-456/') }

      it 'extracts uuid from url' do
        expect(file.uuid).to eq('extracted-uuid-456')
      end
    end

    context 'when neither uuid nor url is set' do
      let(:file) { described_class.new({}) }

      it 'returns nil' do
        expect(file.uuid).to be_nil
      end
    end
  end

  describe '#cdn_url' do
    context 'when url is already set' do
      let(:file) { described_class.new(url: 'https://ucarecdn.com/existing-url/') }

      it 'returns the existing url' do
        expect(file.cdn_url).to eq('https://ucarecdn.com/existing-url/')
      end
    end

    context 'when url is not set' do
      let(:file) { described_class.new(uuid: 'generated-uuid-789') }

      it 'generates cdn_url from uuid' do
        expect(file.cdn_url).to eq('https://ucarecdn.com/generated-uuid-789/')
      end
    end
  end

  describe '#load' do
    let(:file) { described_class.new(uuid: uuid) }

    before do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:info)
        .with(uuid: uuid, params: {}, request_options: {})
        .and_return(response_body)
    end

    it 'loads file metadata' do
      result = file.load

      expect(result).to eq(file)
      expect(file.datetime_stored).to eq('2018-11-26T12:49:10.477888Z')
      expect(file.original_filename).to eq('file.jpg')
    end
  end

  describe '.info' do
    let(:uuid) { 'test-uuid-123' }
    let(:response_body) do
      {
        'uuid' => uuid,
        'original_filename' => 'test.jpg',
        'size' => 1024
      }
    end

    it 'fetches file info by UUID' do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:info)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)

      result = described_class.info(uuid: uuid)

      expect(result).to be_a(described_class)
      expect(result.uuid).to eq(uuid)
      expect(result.original_filename).to eq('test.jpg')
    end
  end

  describe '.file' do
    let(:uuid) { 'test-uuid-456' }
    let(:params) { { include: 'appdata' } }
    let(:response_body) do
      {
        'uuid' => uuid,
        'original_filename' => 'test2.jpg',
        'appdata' => { 'key' => 'value' }
      }
    end

    it 'fetches file info with parameters' do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:info)
        .with(uuid: uuid, params: params, request_options: {})
        .and_return(response_body)

      result = described_class.file(uuid: uuid, params: params)

      expect(result).to be_a(described_class)
      expect(result.uuid).to eq(uuid)
      expect(result.appdata).to eq({ 'key' => 'value' })
    end
  end

  describe 'conversion error handling' do
    let(:file) { described_class.new(uuid: uuid) }

    context 'when params are not a hash' do
      it 'raises ConversionError for invalid params type' do
        expect do
          file.convert_document(params: 'invalid')
        end.to raise_error(Uploadcare::Exception::ConversionError, 'The first argument must be a Hash')
      end
    end

    context 'when ConversionError is not defined' do
      it 'raises ArgumentError for invalid params type' do
        hide_const('Uploadcare::Exception::ConversionError')

        expect do
          file.convert_document(params: 'invalid')
        end.to raise_error(ArgumentError, 'The first argument must be a Hash')
      end
    end

    context 'when converter does not respond to expected methods' do
      let(:params) { { format: 'pdf' } }
      let(:bad_converter) { Class.new }

      it 'raises ConversionError' do
        expect do
          file.send(:perform_conversion, bad_converter, params, {}, request_options: {})
        end.to raise_error(Uploadcare::Exception::ConversionError, /does not respond to/)
      end
    end

    context 'when conversion returns unexpected result' do
      let(:params) { { format: 'pdf' } }
      let(:unexpected_result) { 'unexpected string' }

      before do
        allow(Uploadcare::DocumentConverter).to receive(:convert_document)
          .and_return(unexpected_result)
      end

      it 'returns the result as-is' do
        result = file.convert_document(params: params)
        expect(result).to eq(unexpected_result)
      end
    end

    context 'when conversion returns hash without uuid' do
      let(:params) { { format: 'pdf' } }
      let(:result_without_uuid) do
        {
          'result' => [{ 'token' => '12345' }]
        }
      end

      before do
        allow(Uploadcare::DocumentConverter).to receive(:convert_document)
          .and_return(result_without_uuid)
      end

      it 'returns the result as-is' do
        result = file.convert_document(params: params)
        expect(result).to eq(result_without_uuid)
      end
    end
  end
end
