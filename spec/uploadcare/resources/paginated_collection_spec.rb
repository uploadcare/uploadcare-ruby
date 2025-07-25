# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::PaginatedCollection do
  let(:resource_class) { Uploadcare::File }
  let(:client) { double('client', config: double('config')) }

  let(:resources) do
    [
      { uuid: '1', size: 100 },
      { uuid: '2', size: 200 }
    ].map { |attrs| resource_class.new(attrs, client.config) }
  end

  let(:collection_params) do
    {
      resources: resources,
      next_page: 'https://api.uploadcare.com/files/?limit=2&offset=2',
      previous_page: nil,
      per_page: 2,
      total: 10,
      client: client,
      resource_class: resource_class
    }
  end

  let(:collection) { described_class.new(collection_params) }

  describe '#initialize' do
    it 'sets all attributes' do
      expect(collection.resources).to eq(resources)
      expect(collection.next_page_url).to eq('https://api.uploadcare.com/files/?limit=2&offset=2')
      expect(collection.previous_page_url).to be_nil
      expect(collection.per_page).to eq(2)
      expect(collection.total).to eq(10)
      expect(collection.client).to eq(client)
      expect(collection.resource_class).to eq(resource_class)
    end
  end

  describe '#each' do
    it 'yields each resource' do
      yielded_resources = collection.map { |resource| resource }
      expect(yielded_resources).to eq(resources)
    end

    it 'returns an enumerator when no block given' do
      expect(collection.each).to be_a(Enumerator)
    end

    it 'is enumerable' do
      expect(collection).to be_a(Enumerable)
      expect(collection.map(&:uuid)).to eq(%w[1 2])
    end
  end

  describe '#next_page' do
    context 'when next_page_url exists' do
      let(:next_page_response) do
        {
          'results' => [
            { 'uuid' => '3', 'size' => 300 },
            { 'uuid' => '4', 'size' => 400 }
          ],
          'next' => 'https://api.uploadcare.com/files/?limit=2&offset=4',
          'previous' => 'https://api.uploadcare.com/files/?limit=2&offset=0',
          'per_page' => 2,
          'total' => 10
        }
      end

      before do
        allow(client).to receive(:list).with({ 'limit' => '2', 'offset' => '2' }).and_return(next_page_response)
      end

      it 'fetches the next page' do
        next_page = collection.next_page

        expect(next_page).to be_a(described_class)
        expect(next_page.resources.size).to eq(2)
        expect(next_page.resources.first.uuid).to eq('3')
        expect(next_page.resources.last.uuid).to eq('4')
        expect(next_page.next_page_url).to eq('https://api.uploadcare.com/files/?limit=2&offset=4')
        expect(next_page.previous_page_url).to eq('https://api.uploadcare.com/files/?limit=2&offset=0')
      end
    end

    context 'when next_page_url is nil' do
      let(:collection_params) do
        super().merge(next_page: nil)
      end

      it 'returns nil' do
        expect(collection.next_page).to be_nil
      end
    end
  end

  describe '#previous_page' do
    context 'when previous_page_url exists' do
      let(:collection_params) do
        super().merge(previous_page: 'https://api.uploadcare.com/files/?limit=2&offset=0')
      end

      let(:previous_page_response) do
        {
          'results' => [
            { 'uuid' => '0', 'size' => 50 }
          ],
          'next' => 'https://api.uploadcare.com/files/?limit=2&offset=2',
          'previous' => nil,
          'per_page' => 2,
          'total' => 10
        }
      end

      before do
        allow(client).to receive(:list).with({ 'limit' => '2', 'offset' => '0' }).and_return(previous_page_response)
      end

      it 'fetches the previous page' do
        previous_page = collection.previous_page

        expect(previous_page).to be_a(described_class)
        expect(previous_page.resources.size).to eq(1)
        expect(previous_page.resources.first.uuid).to eq('0')
        expect(previous_page.next_page_url).to eq('https://api.uploadcare.com/files/?limit=2&offset=2')
        expect(previous_page.previous_page_url).to be_nil
      end
    end

    context 'when previous_page_url is nil' do
      it 'returns nil' do
        expect(collection.previous_page).to be_nil
      end
    end
  end

  describe '#all' do
    context 'with multiple pages' do
      let(:page2_response) do
        {
          'results' => [
            { 'uuid' => '3', 'size' => 300 },
            { 'uuid' => '4', 'size' => 400 }
          ],
          'next' => 'https://api.uploadcare.com/files/?limit=2&offset=4',
          'previous' => 'https://api.uploadcare.com/files/?limit=2&offset=0',
          'per_page' => 2,
          'total' => 10
        }
      end

      let(:page3_response) do
        {
          'results' => [
            { 'uuid' => '5', 'size' => 500 }
          ],
          'next' => nil,
          'previous' => 'https://api.uploadcare.com/files/?limit=2&offset=2',
          'per_page' => 2,
          'total' => 10
        }
      end

      before do
        allow(client).to receive(:list).with({ 'limit' => '2', 'offset' => '2' }).and_return(page2_response)
        allow(client).to receive(:list).with({ 'limit' => '2', 'offset' => '4' }).and_return(page3_response)
      end

      it 'fetches all resources from all pages' do
        all_resources = collection.all

        expect(all_resources.size).to eq(5)
        expect(all_resources.map(&:uuid)).to eq(%w[1 2 3 4 5])
        expect(all_resources.map(&:size)).to eq([100, 200, 300, 400, 500])
      end

      it 'returns a new array without modifying original resources' do
        original_resources = collection.resources.dup
        all_resources = collection.all

        expect(collection.resources).to eq(original_resources)
        expect(all_resources).not_to be(collection.resources)
      end
    end

    context 'with single page' do
      let(:collection_params) do
        super().merge(next_page: nil)
      end

      it 'returns only current page resources' do
        all_resources = collection.all

        expect(all_resources.size).to eq(2)
        expect(all_resources.map(&:uuid)).to eq(%w[1 2])
      end
    end

    context 'with empty collection' do
      let(:collection_params) do
        super().merge(resources: [], next_page: nil)
      end

      it 'returns empty array' do
        expect(collection.all).to eq([])
      end
    end
  end

  describe '#extract_params_from_url' do
    it 'extracts query parameters from URL' do
      url = 'https://api.uploadcare.com/files/?limit=10&offset=20&stored=true'
      params = collection.send(:extract_params_from_url, url)

      expect(params).to eq({
                             'limit' => '10',
                             'offset' => '20',
                             'stored' => 'true'
                           })
    end

    it 'handles URLs without query parameters' do
      url = 'https://api.uploadcare.com/files/'
      params = collection.send(:extract_params_from_url, url)

      expect(params).to eq({})
    end

    it 'handles complex query parameters' do
      url = 'https://api.uploadcare.com/files/?ordering=-datetime_uploaded&removed=false'
      params = collection.send(:extract_params_from_url, url)

      expect(params).to eq({
                             'ordering' => '-datetime_uploaded',
                             'removed' => 'false'
                           })
    end
  end

  describe 'edge cases' do
    context 'with nil client' do
      let(:collection_params) do
        super().merge(client: nil)
      end

      it 'raises error when trying to fetch pages' do
        expect { collection.next_page }.to raise_error(NoMethodError)
      end
    end

    context 'with invalid URL' do
      let(:collection_params) do
        super().merge(next_page: 'not a valid url')
      end

      it 'raises error when trying to fetch next page' do
        expect { collection.next_page }.to raise_error(URI::InvalidURIError)
      end
    end

    context 'when API returns unexpected response' do
      before do
        allow(client).to receive(:list).and_return({})
      end

      it 'handles missing results gracefully' do
        expect { collection.next_page }.to raise_error(NoMethodError)
      end
    end
  end
end
