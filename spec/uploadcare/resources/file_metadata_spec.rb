# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Resources::FileMetadata do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:rest) { instance_double(Uploadcare::Api::Rest) }
  let(:rest_metadata) { instance_double(Uploadcare::Api::Rest::FileMetadata) }
  let(:api) { instance_double(Uploadcare::Client::Api, rest: rest) }

  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

  before do
    allow(client).to receive(:api).and_return(api)
    allow(rest).to receive(:file_metadata).and_return(rest_metadata)
  end

  describe '#initialize' do
    it 'initializes with empty metadata hash' do
      metadata = described_class.new({}, client)
      expect(metadata.to_h).to eq({})
    end
  end

  describe 'class methods' do
    describe '.index' do
      it 'returns metadata hash for a file' do
        allow(rest_metadata).to receive(:index)
          .with(uuid: file_uuid, request_options: {})
          .and_return(Uploadcare::Result.success({ 'key1' => 'value1', 'key2' => 'value2' }))

        result = described_class.index(uuid: file_uuid, client: client)
        expect(result).to eq({ 'key1' => 'value1', 'key2' => 'value2' })
      end
    end

    describe '.show' do
      it 'returns a single metadata value' do
        allow(rest_metadata).to receive(:show)
          .with(uuid: file_uuid, key: 'key1', request_options: {})
          .and_return(Uploadcare::Result.success('value1'))

        result = described_class.show(uuid: file_uuid, key: 'key1', client: client)
        expect(result).to eq('value1')
      end
    end

    describe '.update' do
      it 'updates a metadata key and returns the value' do
        allow(rest_metadata).to receive(:update)
          .with(uuid: file_uuid, key: 'key1', value: 'new-value', request_options: {})
          .and_return(Uploadcare::Result.success('new-value'))

        result = described_class.update(uuid: file_uuid, key: 'key1', value: 'new-value', client: client)
        expect(result).to eq('new-value')
      end
    end

    describe '.delete' do
      it 'deletes a metadata key' do
        allow(rest_metadata).to receive(:delete)
          .with(uuid: file_uuid, key: 'key1', request_options: {})
          .and_return(Uploadcare::Result.success(nil))

        expect do
          described_class.delete(uuid: file_uuid, key: 'key1', client: client)
        end.not_to raise_error
      end
    end
  end

  describe 'instance methods' do
    let(:metadata_instance) do
      instance = described_class.new({ 'uuid' => file_uuid }, client)
      instance.instance_variable_set(:@uuid, file_uuid)
      instance
    end

    describe '#index' do
      it 'fetches all metadata and stores it internally' do
        allow(rest_metadata).to receive(:index)
          .with(uuid: file_uuid, request_options: {})
          .and_return(Uploadcare::Result.success({ 'key1' => 'value1' }))

        result = metadata_instance.index
        expect(result).to eq(metadata_instance)
        expect(metadata_instance['key1']).to eq('value1')
        expect(metadata_instance.to_h).to eq({ 'key1' => 'value1' })
      end
    end

    describe '#[] and #[]=' do
      it 'gets and sets metadata locally' do
        metadata_instance['color'] = 'red'
        expect(metadata_instance['color']).to eq('red')
      end

      it 'converts symbol keys to strings' do
        metadata_instance[:shape] = 'circle'
        expect(metadata_instance[:shape]).to eq('circle')
        expect(metadata_instance['shape']).to eq('circle')
      end
    end

    describe '#to_h' do
      it 'returns a copy of the metadata hash' do
        metadata_instance['a'] = '1'
        metadata_instance['b'] = '2'
        h = metadata_instance.to_h
        expect(h).to eq({ 'a' => '1', 'b' => '2' })

        h['c'] = '3'
        expect(metadata_instance['c']).to be_nil
      end
    end

    describe '#update' do
      it 'persists a key-value pair to the server' do
        allow(rest_metadata).to receive(:update)
          .with(uuid: file_uuid, key: 'color', value: 'blue', request_options: {})
          .and_return(Uploadcare::Result.success('blue'))

        result = metadata_instance.update(key: 'color', value: 'blue')
        expect(result).to eq('blue')
        expect(metadata_instance['color']).to eq('blue')
      end

      it 'does not update local metadata when uuid differs' do
        allow(rest_metadata).to receive(:update)
          .with(uuid: 'other-uuid', key: 'color', value: 'blue', request_options: {})
          .and_return(Uploadcare::Result.success('blue'))

        metadata_instance.update(key: 'color', value: 'blue', uuid: 'other-uuid')
        expect(metadata_instance['color']).to be_nil
      end
    end

    describe '#show' do
      it 'retrieves a single metadata value from the server' do
        allow(rest_metadata).to receive(:show)
          .with(uuid: file_uuid, key: 'color', request_options: {})
          .and_return(Uploadcare::Result.success('green'))

        result = metadata_instance.show(key: 'color')
        expect(result).to eq('green')
      end
    end

    describe '#delete' do
      it 'deletes a metadata key on the server' do
        metadata_instance['temp'] = 'data'
        allow(rest_metadata).to receive(:delete)
          .with(uuid: file_uuid, key: 'temp', request_options: {})
          .and_return(Uploadcare::Result.success(nil))

        metadata_instance.delete(key: 'temp')
        expect(metadata_instance['temp']).to be_nil
      end

      it 'does not delete local metadata when uuid differs' do
        metadata_instance['temp'] = 'data'
        allow(rest_metadata).to receive(:delete)
          .with(uuid: 'other-uuid', key: 'temp', request_options: {})
          .and_return(Uploadcare::Result.success(nil))

        metadata_instance.delete(key: 'temp', uuid: 'other-uuid')
        expect(metadata_instance['temp']).to eq('data')
      end
    end
  end
end
