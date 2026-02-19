# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::FileMetadata do
  subject(:file_metadata) { described_class.new }

  let(:uuid) { 'file-uuid' }
  let(:key) { 'custom-key' }
  let(:value) { 'custom-value' }
  let(:response_body) { { key => value } }

  describe '#index' do
    it 'retrieves all metadata keys and values' do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:index)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)

      result = file_metadata.index(uuid: uuid)
      expect(result).to be_a(described_class)
    end

    it 'uses existing uuid when not provided' do
      file_metadata.instance_variable_set(:@uuid, uuid)
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:index)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)

      result = file_metadata.index
      expect(result).to be_a(described_class)
    end
  end

  describe '#[]' do
    before do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:index)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)
      file_metadata.index(uuid: uuid)
    end

    it 'accesses metadata values dynamically' do
      expect(file_metadata[key]).to eq(value)
    end
  end

  describe '#[]=' do
    it 'sets metadata values dynamically' do
      file_metadata[key] = value
      expect(file_metadata[key]).to eq(value)
    end
  end

  describe '#to_h' do
    before do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:index)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)
      file_metadata.index(uuid: uuid)
    end

    it 'returns all metadata as a hash' do
      expect(file_metadata.to_h).to eq(response_body)
    end
  end

  describe '#show' do
    it 'retrieves a specific metadata key value' do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:show)
        .with(uuid: uuid, key: key, request_options: {})
        .and_return(value)

      result = file_metadata.show(uuid: uuid, key: key)
      expect(result).to eq(value)
    end

    it 'uses existing uuid when not provided' do
      file_metadata.instance_variable_set(:@uuid, uuid)
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:show)
        .with(uuid: uuid, key: key, request_options: {})
        .and_return(value)

      result = file_metadata.show(key: key)
      expect(result).to eq(value)
    end
  end

  describe '#update' do
    it 'updates a specific metadata key value' do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:update)
        .with(uuid: uuid, key: key, value: value, request_options: {})
        .and_return(value)

      result = file_metadata.update(uuid: uuid, key: key, value: value)
      expect(result).to eq(value)
    end

    it 'uses existing uuid when not provided' do
      file_metadata.instance_variable_set(:@uuid, uuid)
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:update)
        .with(uuid: uuid, key: key, value: value, request_options: {})
        .and_return(value)

      result = file_metadata.update(key: key, value: value)
      expect(result).to eq(value)
    end

    it 'updates in-memory metadata cache' do
      file_metadata.instance_variable_set(:@uuid, uuid)
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:update)
        .with(uuid: uuid, key: key, value: value, request_options: {})
        .and_return(value)

      file_metadata.update(uuid: uuid, key: key, value: value)
      expect(file_metadata[key]).to eq(value)
    end

    it 'does not update in-memory metadata cache when uuid targets a different file' do
      other_uuid = 'other-file-uuid'
      original_value = 'original-value'

      file_metadata.instance_variable_set(:@uuid, uuid)
      file_metadata[key] = original_value

      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:update)
        .with(uuid: other_uuid, key: key, value: value, request_options: {})
        .and_return(value)

      result = file_metadata.update(uuid: other_uuid, key: key, value: value)

      expect(result).to eq(value)
      expect(file_metadata[key]).to eq(original_value)
    end
  end

  describe '#delete' do
    it 'deletes a specific metadata key' do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:delete)
        .with(uuid: uuid, key: key, request_options: {})
        .and_return(nil)

      result = file_metadata.delete(uuid: uuid, key: key)
      expect(result).to be_nil
    end

    it 'uses existing uuid when not provided' do
      file_metadata.instance_variable_set(:@uuid, uuid)
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:delete)
        .with(uuid: uuid, key: key, request_options: {})
        .and_return(nil)

      result = file_metadata.delete(key: key)
      expect(result).to be_nil
    end

    it 'removes value from in-memory metadata cache' do
      file_metadata.instance_variable_set(:@uuid, uuid)
      file_metadata[key] = value
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:delete)
        .with(uuid: uuid, key: key, request_options: {})
        .and_return(nil)

      file_metadata.delete(uuid: uuid, key: key)
      expect(file_metadata[key]).to be_nil
    end

    it 'does not remove in-memory metadata cache when uuid targets a different file' do
      other_uuid = 'other-file-uuid'

      file_metadata.instance_variable_set(:@uuid, uuid)
      file_metadata[key] = value

      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:delete)
        .with(uuid: other_uuid, key: key, request_options: {})
        .and_return(nil)

      result = file_metadata.delete(uuid: other_uuid, key: key)

      expect(result).to be_nil
      expect(file_metadata[key]).to eq(value)
    end
  end
  describe '.index' do
    it 'retrieves all metadata keys and values' do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:index)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)

      result = described_class.index(uuid: uuid)
      expect(result).to eq(response_body)
    end

    it 'uses default configuration when none provided' do
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(config: Uploadcare.configuration).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:index).and_return(response_body)

      described_class.index(uuid: uuid)
    end

    it 'uses the provided configuration' do
      config = Uploadcare.configuration
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(config: config).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:index).and_return(response_body)

      described_class.index(uuid: uuid, config: config)
    end
  end

  describe '.show' do
    it 'retrieves a specific metadata key value' do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:show)
        .with(uuid: uuid, key: key, request_options: {})
        .and_return(value)

      result = described_class.show(uuid: uuid, key: key)
      expect(result).to eq(value)
    end

    it 'uses default configuration when none provided' do
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(config: Uploadcare.configuration).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:show).and_return(value)

      described_class.show(uuid: uuid, key: key)
    end

    it 'uses the provided configuration' do
      config = Uploadcare.configuration
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(config: config).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:show).and_return(value)

      described_class.show(uuid: uuid, key: key, config: config)
    end
  end

  describe '.update' do
    it 'updates a specific metadata key value' do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:update)
        .with(uuid: uuid, key: key, value: value, request_options: {})
        .and_return(value)

      result = described_class.update(uuid: uuid, key: key, value: value)
      expect(result).to eq(value)
    end

    it 'uses default configuration when none provided' do
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(config: Uploadcare.configuration).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:update).and_return(value)

      described_class.update(uuid: uuid, key: key, value: value)
    end

    it 'uses the provided configuration' do
      config = Uploadcare.configuration
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(config: config).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:update).and_return(value)

      described_class.update(uuid: uuid, key: key, value: value, config: config)
    end
  end

  describe '.delete' do
    it 'deletes a specific metadata key' do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:delete)
        .with(uuid: uuid, key: key, request_options: {})
        .and_return(nil)

      result = described_class.delete(uuid: uuid, key: key)
      expect(result).to be_nil
    end

    it 'uses default configuration when none provided' do
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(config: Uploadcare.configuration).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:delete).and_return(nil)

      described_class.delete(uuid: uuid, key: key)
    end

    it 'uses the provided configuration' do
      config = Uploadcare.configuration
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(config: config).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:delete).and_return(nil)

      described_class.delete(uuid: uuid, key: key, config: config)
    end
  end
end
