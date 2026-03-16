# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Resources::Group do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:rest) { instance_double(Uploadcare::Api::Rest) }
  let(:rest_groups) { instance_double(Uploadcare::Api::Rest::Groups) }
  let(:upload_api) { instance_double(Uploadcare::Api::Upload) }
  let(:upload_groups) { double('upload_groups') }
  let(:api) { instance_double(Uploadcare::Client::Api, rest: rest, upload: upload_api) }

  let(:group_id) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890~3' }
  let(:group_attrs) do
    {
      'id' => group_id,
      'datetime_created' => '2025-01-01T00:00:00Z',
      'datetime_stored' => nil,
      'files_count' => 3,
      'cdn_url' => "https://ucarecdn.com/#{group_id}/",
      'url' => "https://api.uploadcare.com/groups/#{group_id}/",
      'files' => []
    }
  end

  before do
    allow(client).to receive(:api).and_return(api)
    allow(rest).to receive(:groups).and_return(rest_groups)
    allow(upload_api).to receive(:groups).and_return(upload_groups)
  end

  describe 'ATTRIBUTES' do
    it 'defines expected attributes' do
      expect(described_class::ATTRIBUTES).to include(:id, :files_count, :cdn_url, :files, :datetime_created)
    end
  end

  describe '.find' do
    it 'fetches group info by ID' do
      allow(rest_groups).to receive(:info)
        .with(uuid: group_id, request_options: {})
        .and_return(Uploadcare::Result.success(group_attrs))

      group = described_class.find(group_id: group_id, client: client)
      expect(group).to be_a(described_class)
      expect(group.id).to eq(group_id)
      expect(group.files_count).to eq(3)
    end

    it 'is aliased as retrieve and info' do
      expect(described_class).to respond_to(:retrieve)
      expect(described_class).to respond_to(:info)
    end
  end

  describe '.list' do
    let(:list_response) do
      {
        'results' => [group_attrs],
        'next' => nil,
        'previous' => nil,
        'per_page' => 10,
        'total' => 1
      }
    end

    it 'returns a Paginated collection of groups' do
      allow(rest_groups).to receive(:list)
        .with(params: {}, request_options: {})
        .and_return(Uploadcare::Result.success(list_response))

      result = described_class.list(client: client)
      expect(result).to be_a(Uploadcare::Collections::Paginated)
      expect(result.resources.length).to eq(1)
      expect(result.resources.first).to be_a(described_class)
      expect(result.total).to eq(1)
    end

    it 'passes params through' do
      allow(rest_groups).to receive(:list)
        .with(params: { limit: 5 }, request_options: {})
        .and_return(Uploadcare::Result.success(list_response))

      result = described_class.list(params: { limit: 5 }, client: client)

      expect(result).to be_a(Uploadcare::Collections::Paginated)
    end
  end

  describe '.create' do
    it 'creates a group from file UUIDs' do
      uuids = %w[uuid-1 uuid-2 uuid-3]
      allow(upload_groups).to receive(:create)
        .with(files: uuids, request_options: {})
        .and_return(Uploadcare::Result.success(group_attrs))

      group = described_class.create(uuids: uuids, client: client)
      expect(group).to be_a(described_class)
      expect(group.id).to eq(group_id)
      expect(group.files_count).to eq(3)
    end
  end

  describe '#reload' do
    it 'reloads group info from the API' do
      group = described_class.new(group_attrs, client)
      updated_attrs = group_attrs.merge('files_count' => 5)

      allow(rest_groups).to receive(:info)
        .with(uuid: group_id, request_options: {})
        .and_return(Uploadcare::Result.success(updated_attrs))

      result = group.reload
      expect(result).to eq(group)
      expect(group.files_count).to eq(5)
    end

    it 'is aliased as load' do
      group = described_class.new(group_attrs, client)
      expect(group).to respond_to(:load)
    end
  end

  describe '#delete' do
    it 'deletes the group' do
      group = described_class.new(group_attrs, client)

      allow(rest_groups).to receive(:delete)
        .with(uuid: group_id, request_options: {})
        .and_return(Uploadcare::Result.success(nil))

      expect { group.delete }.not_to raise_error
    end
  end

  describe '#id' do
    it 'returns the id attribute when set' do
      group = described_class.new(group_attrs, client)
      expect(group.id).to eq(group_id)
    end

    it 'falls back to uuid when id not set' do
      group = described_class.new({ 'uuid' => 'some-uuid' }, client)
      expect(group.id).to eq('some-uuid')
    end

    it 'extracts id from cdn_url when id and uuid not set' do
      group = described_class.new({ 'cdn_url' => "https://ucarecdn.com/#{group_id}/" }, client)
      expect(group.id).to eq(group_id)
    end

    it 'returns nil when no id source is available' do
      group = described_class.new({}, client)
      expect(group.id).to be_nil
    end
  end

  describe '#cdn_url' do
    it 'returns the cdn_url attribute when set' do
      group = described_class.new(group_attrs, client)
      expect(group.cdn_url).to eq("https://ucarecdn.com/#{group_id}/")
    end

    it 'builds CDN URL from config and id when cdn_url not set' do
      group = described_class.new({ 'id' => group_id }, client)
      expect(group.cdn_url).to eq("https://ucarecdn.com/#{group_id}/")
    end
  end

  describe '#file_cdn_urls' do
    it 'returns array of nth CDN URLs for each file' do
      group = described_class.new(group_attrs, client)
      urls = group.file_cdn_urls
      expect(urls.length).to eq(3)
      expect(urls[0]).to eq("https://ucarecdn.com/#{group_id}/nth/0/")
      expect(urls[1]).to eq("https://ucarecdn.com/#{group_id}/nth/1/")
      expect(urls[2]).to eq("https://ucarecdn.com/#{group_id}/nth/2/")
    end

    it 'returns empty array when files_count is nil' do
      group = described_class.new({ 'id' => group_id }, client)
      expect(group.file_cdn_urls).to eq([])
    end
  end
end
