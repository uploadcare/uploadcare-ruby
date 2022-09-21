# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Entity
    RSpec.describe FileMetadata do
      subject { FileMetadata }

      let(:uuid) { '2e17f5d1-d423-4de6-8ee5-6773cc4a7fa6' }
      let(:key) { 'subsystem' }

      it 'responds to expected methods' do
        expect(subject).to respond_to(:index, :show, :update, :delete)
      end

      it 'represents a file_metadata as string' do
        VCR.use_cassette('file_metadata_index') do
          response = subject.index(uuid)
          expect(response[:subsystem]).to eq('test')
        end
      end

      it 'raises error for nonexistent file' do
        VCR.use_cassette('file_metadata_index_nonexistent_uuid') do
          uuid = 'nonexistent'
          expect { subject.index(uuid) }.to raise_error(RequestError)
        end
      end

      it 'show file_metadata' do
        VCR.use_cassette('file_metadata_show') do
          response = subject.show(uuid, key)
          expect(response).to eq('test')
        end
      end

      it 'raises error when trying to show nonexistent key' do
        VCR.use_cassette('file_metadata_show_nonexistent_key') do
          key = 'nonexistent'
          expect { subject.show(uuid, key) }.to raise_error(RequestError)
        end
      end

      it 'update file_metadata' do
        VCR.use_cassette('file_metadata_update') do
          new_value = 'new test value'
          response = subject.update(uuid, key, new_value)
          expect(response).to eq(new_value)
        end
      end

      it 'create file_metadata if it does not exist' do
        VCR.use_cassette('file_metadata_create') do
          key = 'new_key'
          value = 'some value'
          response = subject.update(uuid, key, value)
          expect(response).to eq(value)
        end
      end

      it 'delete file_metadata' do
        VCR.use_cassette('file_metadata_delete') do
          response = subject.delete(uuid, key)
          expect(response).to eq('200 OK')
        end
      end
    end
  end
end
