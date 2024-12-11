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
      allow_any_instance_of(Uploadcare::FileClient).to receive(:get).with('files/', {}).and_return(response_body)
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
      allow_any_instance_of(Uploadcare::FileClient).to receive(:put).with("/files/#{uuid}/storage/").and_return(response_body)
    end

    it { is_expected.to be_a(Uploadcare::File) }
    it { expect(subject.uuid).to eq(uuid) }
  end

  describe '#delete' do
    subject { file.delete }
    before do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:delete).with(uuid).and_return(response_body)
    end

    it { is_expected.to be_a(Uploadcare::File) }
    it { expect(subject.uuid).to eq(uuid) }
  end

  describe '#info' do
    subject { file.info }
    before do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:get).with("/files/#{uuid}/").and_return(response_body)
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
      subject { described_class.batch_store(uuids) }

      before do
        allow_any_instance_of(Uploadcare::FileClient).to receive(:put).with('/files/storage/', uuids).and_return(response_body)
      end

      it { is_expected.to be_a(Uploadcare::BatchFileResult) }
      it { expect(subject.status).to eq(200) }
      it { expect(subject.result.first).to be_a(Uploadcare::File) }
      it { expect(subject.problems).not_to be_empty }
    end

    describe '.batch_delete' do
      subject { described_class.batch_delete(uuids) }

      before do
        allow_any_instance_of(Uploadcare::FileClient).to receive(:del).with('/files/storage/', uuids).and_return(response_body)
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

    subject { file.local_copy(options) }

    before do
      file.uuid = source
      allow_any_instance_of(Uploadcare::FileClient).to receive(:local_copy)
        .with(source, options)
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

    subject { file.remote_copy(target, options) }

    before do
      file.uuid = source
      allow_any_instance_of(Uploadcare::FileClient).to receive(:remote_copy)
        .with(source, target, options)
        .and_return(response_body)
    end

    it { is_expected.to be_a(String) }
    it { is_expected.to eq(s3_url) }
  end

  # There is a duplication of assertions for both class and instance methods
  # Can be refactored later
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

    subject { described_class.local_copy(source, options) }

    before do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:local_copy)
        .with(source, options)
        .and_return(response_body)
    end

    it { is_expected.to be_a(Uploadcare::File) }

    it { expect(subject.uuid).to eq(source) }
    it { expect(subject.original_filename).to eq('copy_of_file.jpg') }
    it { expect(subject.size).to eq(12_345) }
  end

  # There is a duplication of assertions for both class and instance methods
  # Can be refactored later
  describe '.remote_copy' do
    let(:source) { SecureRandom.uuid }
    let(:target) { 'custom_storage_name' }
    let(:s3_url) { 's3://mybucket/copied_file.jpg' }
    let(:options) { { make_public: false, pattern: '${default}' } }
    let(:response_body) { { 'type' => 'url', 'result' => s3_url } }

    subject { described_class.remote_copy(source, target, options) }

    before do
      allow_any_instance_of(Uploadcare::FileClient).to receive(:remote_copy)
        .with(source, target, options)
        .and_return(response_body)
    end

    it { is_expected.to be_a(String) }
    it { is_expected.to eq(s3_url) }
  end
end
