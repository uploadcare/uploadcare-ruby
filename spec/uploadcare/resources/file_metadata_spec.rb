# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::FileMetadata do
  subject(:file_metadata) { described_class.new }

  let(:uuid) { 'file-uuid' }
  let(:key) { 'custom-key' }
  let(:value) { 'custom-value' }
  let(:response_body) { { key => value } }

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
end
