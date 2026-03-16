# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Collections::Paginated do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:api_client) { double('api_client') }
  let(:resource_class) { Uploadcare::Resources::File }

  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }
  let(:file_resource) do
    resource_class.new({ 'uuid' => file_uuid, 'original_filename' => 'photo.jpg' }, client)
  end

  let(:collection) do
    described_class.new(
      resources: [file_resource],
      next_page: 'https://api.uploadcare.com/files/?limit=10&offset=10',
      previous_page: nil,
      per_page: 10,
      total: 25,
      api_client: api_client,
      resource_class: resource_class,
      client: client
    )
  end

  describe '#initialize' do
    it 'stores all provided parameters' do
      expect(collection.resources).to eq([file_resource])
      expect(collection.next_page_url).to eq('https://api.uploadcare.com/files/?limit=10&offset=10')
      expect(collection.previous_page_url).to be_nil
      expect(collection.per_page).to eq(10)
      expect(collection.total).to eq(25)
      expect(collection.api_client).to eq(api_client)
      expect(collection.resource_class).to eq(resource_class)
      expect(collection.client).to eq(client)
    end

    it 'defaults resources to empty array' do
      empty = described_class.new
      expect(empty.resources).to eq([])
    end
  end

  describe 'Enumerable' do
    it 'includes Enumerable' do
      expect(described_class).to include(Enumerable)
    end

    it 'delegates each to resources' do
      uuids = collection.map(&:uuid)
      expect(uuids).to eq([file_uuid])
    end

    it 'supports map' do
      names = collection.map(&:original_filename)
      expect(names).to eq(['photo.jpg'])
    end

    it 'supports count' do
      expect(collection.count).to eq(1)
    end

    it 'supports first' do
      expect(collection.first).to eq(file_resource)
    end

    it 'supports to_a' do
      expect(collection.to_a).to eq([file_resource])
    end
  end

  describe '#next_page' do
    it 'fetches the next page of results' do
      next_file_attrs = { 'uuid' => 'next-page-uuid', 'original_filename' => 'page2.jpg' }
      next_response = {
        'results' => [next_file_attrs],
        'next' => nil,
        'previous' => 'https://api.uploadcare.com/files/?limit=10&offset=0',
        'per_page' => 10,
        'total' => 25
      }

      allow(api_client).to receive(:list)
        .with(params: { 'limit' => '10', 'offset' => '10' })
        .and_return(Uploadcare::Result.success(next_response))

      page2 = collection.next_page
      expect(page2).to be_a(described_class)
      expect(page2.resources.length).to eq(1)
      expect(page2.resources.first.uuid).to eq('next-page-uuid')
      expect(page2.next_page_url).to be_nil
      expect(page2.previous_page_url).to eq('https://api.uploadcare.com/files/?limit=10&offset=0')
    end

    it 'returns nil when on the last page' do
      last_page = described_class.new(
        resources: [file_resource],
        next_page: nil,
        per_page: 10,
        total: 5,
        api_client: api_client,
        resource_class: resource_class,
        client: client
      )
      expect(last_page.next_page).to be_nil
    end
  end

  describe '#previous_page' do
    it 'fetches the previous page of results' do
      prev_collection = described_class.new(
        resources: [file_resource],
        next_page: nil,
        previous_page: 'https://api.uploadcare.com/files/?limit=10&offset=0',
        per_page: 10,
        total: 25,
        api_client: api_client,
        resource_class: resource_class,
        client: client
      )

      prev_file_attrs = { 'uuid' => 'prev-page-uuid' }
      prev_response = {
        'results' => [prev_file_attrs],
        'next' => 'https://api.uploadcare.com/files/?limit=10&offset=10',
        'previous' => nil,
        'per_page' => 10,
        'total' => 25
      }

      allow(api_client).to receive(:list)
        .with(params: { 'limit' => '10', 'offset' => '0' })
        .and_return(Uploadcare::Result.success(prev_response))

      page1 = prev_collection.previous_page
      expect(page1).to be_a(described_class)
      expect(page1.resources.first.uuid).to eq('prev-page-uuid')
    end

    it 'returns nil when on the first page' do
      expect(collection.previous_page).to be_nil
    end
  end

  describe '#all' do
    it 'fetches all resources across multiple pages' do
      file2_attrs = { 'uuid' => 'page2-uuid' }
      page2_response = {
        'results' => [file2_attrs],
        'next' => nil,
        'previous' => nil,
        'per_page' => 10,
        'total' => 2
      }

      allow(api_client).to receive(:list)
        .with(params: { 'limit' => '10', 'offset' => '10' })
        .and_return(Uploadcare::Result.success(page2_response))

      all_items = collection.all
      expect(all_items.length).to eq(2)
      expect(all_items.first.uuid).to eq(file_uuid)
      expect(all_items.last.uuid).to eq('page2-uuid')
    end

    it 'returns resources from single page when no next_page' do
      single_page = described_class.new(
        resources: [file_resource],
        next_page: nil,
        per_page: 10,
        total: 1,
        api_client: api_client,
        resource_class: resource_class,
        client: client
      )

      all_items = single_page.all
      expect(all_items.length).to eq(1)
      expect(all_items.first).to eq(file_resource)
    end

    it 'returns empty array when no resources' do
      empty = described_class.new(
        resources: [],
        next_page: nil,
        per_page: 10,
        total: 0,
        api_client: api_client,
        resource_class: resource_class,
        client: client
      )
      expect(empty.all).to eq([])
    end
  end
end
