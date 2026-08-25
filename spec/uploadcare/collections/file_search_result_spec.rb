# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Collections::FileSearchResult do
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
  let(:search_params) do
    {
      phrase: { original_filename: 'invoice' },
      exact: { 'metadata[camera]' => ['Canon'] },
      is_image: false
    }
  end
  let(:first_file) { resource_class.new({ 'uuid' => 'uuid-1' }, client) }
  let(:search_query) { { include: 'appdata', limit: 2 } }
  let(:collection) do
    described_class.new(
      resources: [first_file],
      next_page: 'https://api.uploadcare.com/files/search/?limit=2&offset=50',
      previous_page: nil,
      per_page: 2,
      total: 100,
      api_client: api_client,
      resource_class: resource_class,
      client: client,
      request_options: { timeout: 5 },
      search_params: search_params,
      search_query: search_query
    )
  end

  describe '#next_page' do
    it 'follows the API URL and resends the original search body' do
      response = {
        'results' => [
          {
            'uuid' => 'uuid-2',
            'highlight' => { 'original_filename' => ['<em>invoice</em>.pdf'] }
          }
        ],
        'next' => nil,
        'previous' => 'https://api.uploadcare.com/files/search/?limit=2&offset=48&include=appdata',
        'per_page' => 2,
        'total' => 100
      }
      allow(api_client).to receive(:search)
        .with(
          params: search_params,
          query: { 'include' => 'appdata', 'limit' => '2', 'offset' => '50' },
          request_options: { timeout: 5 }
        )
        .and_return(Uploadcare::Result.success(response))

      page = collection.next_page

      expect(page).to be_a(described_class)
      expect(page.resources.first.uuid).to eq('uuid-2')
      expect(page.resources.first.highlight).to eq(
        'original_filename' => ['<em>invoice</em>.pdf']
      )
      expect(page.search_params).to eq(search_params)
      expect(page.search_query).to eq(search_query)
    end
  end

  describe '#search_query' do
    it 'is copied and frozen so callers cannot alter subsequent page fetches' do
      snapshot = collection.search_query

      search_query[:include] = 'other'

      expect(snapshot).to eq(include: 'appdata', limit: 2)
      expect(snapshot).to be_frozen
      expect(snapshot.fetch(:include)).to be_frozen
    end
  end

  describe '#search_params' do
    it 'is deeply copied and frozen so callers cannot alter subsequent page fetches' do
      snapshot = collection.search_params

      search_params.fetch(:phrase)[:original_filename] = 'receipt'
      search_params.fetch(:exact).fetch('metadata[camera]') << 'Nikon'

      expect(snapshot).to eq(
        phrase: { original_filename: 'invoice' },
        exact: { 'metadata[camera]' => ['Canon'] },
        is_image: false
      )
      expect(snapshot).to be_frozen
      expect(snapshot.fetch(:phrase)).to be_frozen
      expect(snapshot.dig(:phrase, :original_filename)).to be_frozen
      expect(snapshot.dig(:exact, 'metadata[camera]')).to be_frozen
    end
  end

  describe '#all' do
    it 'continues through an empty page that still has a next URL' do
      empty_page = {
        'results' => [],
        'next' => 'https://api.uploadcare.com/files/search/?limit=2&offset=52',
        'previous' => nil,
        'per_page' => 2,
        'total' => 100
      }
      final_page = {
        'results' => [{ 'uuid' => 'uuid-3' }],
        'next' => nil,
        'previous' => nil,
        'per_page' => 2,
        'total' => 100
      }

      allow(api_client).to receive(:search)
        .with(
          params: search_params,
          query: { 'include' => 'appdata', 'limit' => '2', 'offset' => '50' },
          request_options: { timeout: 5 }
        )
        .and_return(Uploadcare::Result.success(empty_page))
      allow(api_client).to receive(:search)
        .with(
          params: search_params,
          query: { 'include' => 'appdata', 'limit' => '2', 'offset' => '52' },
          request_options: { timeout: 5 }
        )
        .and_return(Uploadcare::Result.success(final_page))

      expect(collection.all.map(&:uuid)).to eq(%w[uuid-1 uuid-3])
    end
  end
end
