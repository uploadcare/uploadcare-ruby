# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Group do
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

    it 'returns GroupList containing Group Resources' do
      first_group = subject.resources.first
      expect(first_group).to be_a(described_class)
      expect(first_group.id).to eq('group_uuid_1~2')
      expect(first_group.datetime_created).to eq('2023-11-01T12:49:10.477888Z')
      expect(first_group.files_count).to eq(2)
      expect(first_group.cdn_url).to eq('https://ucarecdn.com/group_uuid_1~2/')
      expect(first_group.url).to eq('https://api.uploadcare.com/groups/group_uuid_1~2/')
    end
  end

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

  describe '#info' do
    before do
      allow_any_instance_of(Uploadcare::GroupClient).to receive(:info).with(uuid).and_return(response_body)
    end

    it 'fetches and assigns group info' do
      result = group.info(uuid)

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
end
