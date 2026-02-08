# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Group do
  let(:uuid) { 'group_uuid_1~2' }
  let(:response_body) do
    {
      'id' => uuid,
      'datetime_created' => '2023-11-01T12:49:10.477888Z',
      'files_count' => 2,
      'cdn_url' => "https://ucarecdn.com/#{uuid}/",
      'url' => "https://api.uploadcare.com/groups/#{uuid}/",
      'files' => [
        {
          'uuid' => 'file_uuid_1',
          'datetime_uploaded' => '2023-11-01T12:49:09.945335Z',
          'is_image' => true,
          'mime_type' => 'image/jpeg',
          'original_filename' => 'file1.jpg',
          'size' => 12_345
        }
      ]
    }
  end

  subject(:group) { described_class.new({}) }

  describe '#list' do
    let(:response_body) do
      {
        'next' => nil,
        'previous' => nil,
        'per_page' => 10,
        'results' => [
          {
            'id' => 'group_uuid_1~2',
            'datetime_created' => '2023-11-01T12:49:10.477888Z',
            'files_count' => 2,
            'cdn_url' => 'https://ucarecdn.com/group_uuid_1~2/',
            'url' => 'https://api.uploadcare.com/groups/group_uuid_1~2/'
          },
          {
            'id' => 'group_uuid_2~3',
            'datetime_created' => '2023-11-02T14:49:10.477888Z',
            'files_count' => 3,
            'cdn_url' => 'https://ucarecdn.com/group_uuid_2~3/',
            'url' => 'https://api.uploadcare.com/groups/group_uuid_2~3/'
          }
        ],
        'total' => 2
      }
    end
    subject { described_class.list }

    before do
      allow_any_instance_of(Uploadcare::GroupClient).to receive(:list).and_return(response_body)
    end

    it { is_expected.to be_a(Uploadcare::PaginatedCollection) }
    it { expect(subject.resources.size).to eq(2) }

    it 'returns a PaginatedCollection containing Group Resources' do
      first_group = subject.resources.first
      expect(first_group).to be_a(described_class)
      expect(first_group.id).to eq('group_uuid_1~2')
      expect(first_group.datetime_created).to eq('2023-11-01T12:49:10.477888Z')
      expect(first_group.files_count).to eq(2)
      expect(first_group.cdn_url).to eq('https://ucarecdn.com/group_uuid_1~2/')
      expect(first_group.url).to eq('https://api.uploadcare.com/groups/group_uuid_1~2/')
    end
  end

  describe '#info' do
    it 'fetches and assigns group info' do
      allow_any_instance_of(Uploadcare::GroupClient).to receive(:info)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)

      result = group.info(uuid: uuid)

      expect(result.id).to eq(uuid)
      expect(result.datetime_created).to eq('2023-11-01T12:49:10.477888Z')
      expect(result.files_count).to eq(2)
      expect(result.cdn_url).to eq("https://ucarecdn.com/#{uuid}/")
      expect(result.url).to eq("https://api.uploadcare.com/groups/#{uuid}/")
      expect(result.files.first['uuid']).to eq('file_uuid_1')
      expect(result.files.first['original_filename']).to eq('file1.jpg')
      expect(result.files.first['size']).to eq(12_345)
    end
  end

  describe '#delete' do
    it 'deletes the group' do
      allow_any_instance_of(Uploadcare::GroupClient).to receive(:delete)
        .with(uuid: uuid, request_options: {})
        .and_return(nil)

      result = group.delete(uuid: uuid)

      expect(result).to be_nil
    end
  end

  describe '.create' do
    let(:uuids) { %w[uuid-1 uuid-2] }
    let(:create_response) do
      {
        'id' => 'new-group-uuid~2',
        'datetime_created' => '2023-11-01T12:49:10.477888Z',
        'files_count' => 2,
        'cdn_url' => 'https://ucarecdn.com/new-group-uuid~2/',
        'files' => uuids.map { |u| { 'uuid' => u } }
      }
    end

    it 'creates a new group' do
      allow_any_instance_of(Uploadcare::UploadGroupClient).to receive(:create_group)
        .with(uuids: uuids, request_options: {})
        .and_return(create_response)

      result = described_class.create(uuids: uuids)

      expect(result).to be_a(described_class)
      expect(result.id).to eq('new-group-uuid~2')
      expect(result.files_count).to eq(2)
    end
  end

  describe '.info' do
    it 'fetches group info as class method' do
      allow_any_instance_of(Uploadcare::GroupClient).to receive(:info)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)

      result = described_class.info(group_id: uuid)

      expect(result).to be_a(described_class)
      expect(result.id).to eq(uuid)
      expect(result.files_count).to eq(2)
    end
  end

  describe '#id' do
    context 'when id is already set' do
      let(:group) { described_class.new({ 'id' => 'test-id' }) }

      it 'returns the id' do
        expect(group.id).to eq('test-id')
      end
    end

    context 'when id is not set but cdn_url is' do
      let(:group) { described_class.new({ 'cdn_url' => 'https://ucarecdn.com/extracted-id~3/' }) }

      it 'extracts id from cdn_url' do
        expect(group.id).to eq('extracted-id~3')
      end
    end

    context 'when neither id nor cdn_url is set' do
      let(:group) { described_class.new({}) }

      it 'returns nil' do
        expect(group.id).to be_nil
      end
    end
  end

  describe '#load' do
    let(:group) { described_class.new({ 'id' => uuid }) }

    it 'loads group metadata' do
      allow_any_instance_of(Uploadcare::GroupClient).to receive(:info)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)

      result = group.load

      expect(result).to eq(group)
      expect(group.datetime_created).to eq('2023-11-01T12:49:10.477888Z')
      expect(group.files_count).to eq(2)
    end
  end

  describe '#cdn_url' do
    context 'when cdn_url is already set' do
      let(:group) { described_class.new({ 'cdn_url' => 'https://ucarecdn.com/existing~2/' }) }

      it 'returns the existing cdn_url' do
        expect(group.cdn_url).to eq('https://ucarecdn.com/existing~2/')
      end
    end

    context 'when cdn_url is not set' do
      let(:group) { described_class.new({ 'id' => 'generated-id~3' }) }

      it 'generates cdn_url from id' do
        expect(group.cdn_url).to eq('https://ucarecdn.com/generated-id~3/')
      end
    end
  end

  describe '#file_cdn_urls' do
    let(:group) { described_class.new({ 'id' => 'test-group~3', 'files_count' => 3 }) }

    it 'returns array of file CDN URLs' do
      urls = group.file_cdn_urls

      expect(urls).to be_an(Array)
      expect(urls.length).to eq(3)
      expect(urls[0]).to eq('https://ucarecdn.com/test-group~3/nth/0/')
      expect(urls[1]).to eq('https://ucarecdn.com/test-group~3/nth/1/')
      expect(urls[2]).to eq('https://ucarecdn.com/test-group~3/nth/2/')
    end
  end
end
