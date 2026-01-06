# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::FileMetadata do
  subject(:file_metadata) { described_class.new }

  let(:uuid) { 'file-uuid' }
  let(:key) { 'custom-key' }
  let(:value) { 'custom-value' }
  let(:response_body) { { key => value } }

  describe '#index' do
    before do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:index).with(uuid).and_return(response_body)
    end

    it 'retrieves all metadata keys and values' do
      result = file_metadata.index(uuid)
      expect(result).to be_a(described_class)
    end
  end

  describe '#show' do
    before do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:show).with(uuid, key).and_return(value)
    end

    it 'retrieves a specific metadata key value' do
      result = file_metadata.show(uuid, key)
      expect(result).to eq(value)
    end
  end

  describe '#update' do
    before do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:update).with(uuid, key, value).and_return(value)
    end

    it 'updates a specific metadata key value' do
      result = file_metadata.update(uuid, key, value)
      expect(result).to eq(value)
    end
  end

  describe '#delete' do
    before do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:delete).with(uuid, key).and_return(nil)
    end

    it 'deletes a specific metadata key' do
      result = file_metadata.delete(uuid, key)
      expect(result).to be_nil
    end
  end

  # Class methods specs for v4.4.3 compatibility
  describe '.index' do
    before do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:index).with(uuid).and_return(response_body)
    end

    it 'retrieves all metadata keys and values' do
      result = described_class.index(uuid)
      expect(result).to eq(response_body)
    end

    it 'uses default configuration when none provided' do
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(Uploadcare.configuration).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:index).and_return(response_body)

      described_class.index(uuid)
    end

    it 'uses the provided configuration' do
      config = Uploadcare.configuration
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(config).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:index).and_return(response_body)

      described_class.index(uuid, config)
    end
  end

  describe '.show' do
    before do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:show).with(uuid, key).and_return(value)
    end

    it 'retrieves a specific metadata key value' do
      result = described_class.show(uuid, key)
      expect(result).to eq(value)
    end

    it 'uses default configuration when none provided' do
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(Uploadcare.configuration).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:show).and_return(value)

      described_class.show(uuid, key)
    end

    it 'uses the provided configuration' do
      config = Uploadcare.configuration
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(config).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:show).and_return(value)

      described_class.show(uuid, key, config)
    end
  end

  describe '.update' do
    before do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:update).with(uuid, key, value).and_return(value)
    end

    it 'updates a specific metadata key value' do
      result = described_class.update(uuid, key, value)
      expect(result).to eq(value)
    end

    it 'uses default configuration when none provided' do
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(Uploadcare.configuration).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:update).and_return(value)

      described_class.update(uuid, key, value)
    end

    it 'uses the provided configuration' do
      config = Uploadcare.configuration
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(config).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:update).and_return(value)

      described_class.update(uuid, key, value, config)
    end
  end

  describe '.delete' do
    before do
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:delete).with(uuid, key).and_return(nil)
    end

    it 'deletes a specific metadata key' do
      result = described_class.delete(uuid, key)
      expect(result).to be_nil
    end

    it 'uses default configuration when none provided' do
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(Uploadcare.configuration).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:delete).and_return(nil)

      described_class.delete(uuid, key)
    end

    it 'uses the provided configuration' do
      config = Uploadcare.configuration
      expect(Uploadcare::FileMetadataClient).to receive(:new).with(config).and_call_original
      allow_any_instance_of(Uploadcare::FileMetadataClient).to receive(:delete).and_return(nil)

      described_class.delete(uuid, key, config)
    end
  end
end
