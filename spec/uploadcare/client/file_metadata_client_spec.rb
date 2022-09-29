# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe FileMetadataClient do
      subject { FileMetadataClient.new }

      let(:uuid) { '2e17f5d1-d423-4de6-8ee5-6773cc4a7fa6' }
      let(:key) { 'subsystem' }

      describe 'index' do
        it 'shows file metadata keys and values' do
          VCR.use_cassette('file_metadata_index') do
            response = subject.index(uuid)
            expect(response.value![:subsystem]).to eq('test')
          end
        end
      end

      describe 'show' do
        it 'shows file metadata value by key' do
          VCR.use_cassette('file_metadata_show') do
            response = subject.show(uuid, key)
            expect(response.value!).to eq('test')
          end
        end
      end

      describe 'update' do
        it 'update file metadata value by key' do
          VCR.use_cassette('file_metadata_update') do
            new_value = 'new test value'
            response = subject.update(uuid, key, new_value)
            expect(response.value!).to eq(new_value)
          end
        end
      end

      describe 'delete' do
        it 'delete a file metadata key' do
          VCR.use_cassette('file_metadata_delete') do
            response = subject.delete(uuid, key)
            expect(response.value!).to be_nil
            expect(response.success?).to be_truthy
          end
        end
      end
    end
  end
end
