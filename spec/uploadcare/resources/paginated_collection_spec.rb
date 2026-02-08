# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe PaginatedCollection do
    let(:mock_client) { double('Client') }
    let(:mock_resource_class) { double('ResourceClass') }
    let(:resources) { [double('Resource1'), double('Resource2')] }
    let(:params) do
      {
        resources: resources,
        next_page: 'https://api.uploadcare.com/files/?page=2',
        previous_page: nil,
        per_page: 100,
        total: 250,
        client: mock_client,
        resource_class: mock_resource_class
      }
    end

    subject { described_class.new(params) }

    describe '#initialize' do
      it 'sets resources' do
        expect(subject.resources).to eq(resources)
      end

      it 'sets next_page_url' do
        expect(subject.next_page_url).to eq('https://api.uploadcare.com/files/?page=2')
      end

      it 'sets previous_page_url' do
        expect(subject.previous_page_url).to be_nil
      end

      it 'sets per_page' do
        expect(subject.per_page).to eq(100)
      end

      it 'sets total' do
        expect(subject.total).to eq(250)
      end

      it 'sets client' do
        expect(subject.client).to eq(mock_client)
      end

      it 'sets resource_class' do
        expect(subject.resource_class).to eq(mock_resource_class)
      end
    end

    describe '#each' do
      it 'iterates over resources' do
        yielded = subject.map { |resource| resource }

        expect(yielded).to eq(resources)
      end

      it 'is enumerable' do
        expect(subject).to be_a(Enumerable)
      end
    end

    describe '#next_page' do
      let(:next_page_response) do
        {
          'results' => [{ 'uuid' => 'uuid-3' }, { 'uuid' => 'uuid-4' }],
          'next' => 'https://api.uploadcare.com/files/?page=3',
          'previous' => 'https://api.uploadcare.com/files/?page=1',
          'per_page' => 100,
          'total' => 250
        }
      end

      before do
        allow(mock_client).to receive(:list).and_return(next_page_response)
        allow(mock_client).to receive(:config).and_return(Uploadcare.configuration)
        allow(mock_resource_class).to receive(:new).and_return(double('Resource'))
      end

      context 'when next page exists' do
        it 'fetches next page' do
          next_collection = subject.next_page

          expect(next_collection).to be_a(described_class)
          expect(mock_client).to have_received(:list).with(hash_including('page' => '2'))
        end

        it 'returns new collection with updated resources' do
          next_collection = subject.next_page

          expect(next_collection.resources.length).to eq(2)
        end
      end

      context 'when no next page' do
        subject do
          described_class.new(params.merge(next_page: nil))
        end

        it 'returns nil' do
          expect(subject.next_page).to be_nil
        end
      end
    end

    describe '#previous_page' do
      let(:previous_page_response) do
        {
          'results' => [{ 'uuid' => 'uuid-1' }, { 'uuid' => 'uuid-2' }],
          'next' => 'https://api.uploadcare.com/files/?page=2',
          'previous' => nil,
          'per_page' => 100,
          'total' => 250
        }
      end

      before do
        allow(mock_client).to receive(:list).and_return(previous_page_response)
        allow(mock_client).to receive(:config).and_return(Uploadcare.configuration)
        allow(mock_resource_class).to receive(:new).and_return(double('Resource'))
      end

      context 'when previous page exists' do
        subject do
          described_class.new(params.merge(
                                previous_page: 'https://api.uploadcare.com/files/?page=1'
                              ))
        end

        it 'fetches previous page' do
          prev_collection = subject.previous_page

          expect(prev_collection).to be_a(described_class)
          expect(mock_client).to have_received(:list)
        end
      end

      context 'when no previous page' do
        it 'returns nil' do
          expect(subject.previous_page).to be_nil
        end
      end
    end

    describe '#fetch_page' do
      let(:page_url) { 'https://api.uploadcare.com/files/?page=2&limit=50' }
      let(:page_response) do
        {
          'results' => [{ 'uuid' => 'uuid-5' }],
          'next' => nil,
          'previous' => 'https://api.uploadcare.com/files/?page=1',
          'per_page' => 50,
          'total' => 250
        }
      end

      before do
        allow(mock_client).to receive(:list).and_return(page_response)
        allow(mock_client).to receive(:config).and_return(Uploadcare.configuration)
        allow(mock_resource_class).to receive(:new).and_return(double('Resource'))
      end

      it 'extracts params from URL' do
        subject.send(:fetch_page, page_url)

        expect(mock_client).to have_received(:list).with(hash_including('page' => '2', 'limit' => '50'))
      end

      it 'returns new collection' do
        result = subject.send(:fetch_page, page_url)

        expect(result).to be_a(described_class)
      end

      it 'returns nil for nil URL' do
        result = subject.send(:fetch_page, nil)

        expect(result).to be_nil
      end
    end

    describe '#extract_params_from_url' do
      it 'extracts query parameters' do
        url = 'https://api.uploadcare.com/files/?page=2&limit=50'
        params = subject.send(:extract_params_from_url, url)

        expect(params).to eq({ 'page' => '2', 'limit' => '50' })
      end

      it 'handles URL without query string' do
        url = 'https://api.uploadcare.com/files/'
        params = subject.send(:extract_params_from_url, url)

        expect(params).to eq({})
      end
    end

    describe '#build_resources' do
      let(:results) do
        [
          { 'uuid' => 'uuid-1', 'size' => 1000 },
          { 'uuid' => 'uuid-2', 'size' => 2000 }
        ]
      end

      before do
        allow(mock_client).to receive(:config).and_return(Uploadcare.configuration)
        allow(mock_resource_class).to receive(:new) do |data, _config|
          double('Resource', uuid: data['uuid'])
        end
      end

      it 'builds resource objects from results' do
        resources = subject.send(:build_resources, results)

        expect(resources.length).to eq(2)
        expect(mock_resource_class).to have_received(:new).twice
      end

      it 'passes config to resource constructor' do
        subject.send(:build_resources, results)

        expect(mock_resource_class).to have_received(:new).with(anything, Uploadcare.configuration).at_least(:once)
      end
    end
  end
end
