# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe File do
    subject { File }
    it 'responds to expected methods' do
      expect(subject).to respond_to(:index, :info, :copy, :delete, :store, :batch_store, :batch_delete)
    end

    it 'represents a file as entity' do
      VCR.use_cassette('file_info') do
        uuid = '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
        file = subject.info(uuid)
        expect(file).to be_a_kind_of(subject)
        expect(file).to respond_to(:image_info, :datetime_uploaded, :uuid, :url, :size, :original_filename)
        expect(file.uuid).to eq(uuid)
      end
    end

    context 'batch_store' do
      it 'returns a list of stored files' do
        VCR.use_cassette('rest_file_batch_store') do
          uuids = ['e9a9f291-cc52-4388-bf65-9feec1c75ff9', 'c724feac-86f7-447c-b2d6-b0ced220173d']
          response = File.batch_store(uuids)
          expect(response.length).to eq 2
          expect(response[0]).to be_a_kind_of(Uploadcare::File)
        end
      end

      it 'returns empty list if those files don`t exist' do
        VCR.use_cassette('rest_file_batch_store_fail') do
          uuids = ['nonexistent', 'another_nonexistent']
          response = File.batch_store(uuids)
          expect(response).to be_empty
        end
      end
    end

    context 'batch_delete' do
      it 'returns a list of deleted files' do
        VCR.use_cassette('rest_file_batch_delete') do
          uuids = ['935ff093-a5cf-48c5-81cf-208511bac6e6', '63be5a6e-9b6b-454b-8aec-9136d5f83d0c']
          response = File.batch_delete(uuids)
          expect(response.length).to eq 2
          expect(response[0]).to be_a_kind_of(Uploadcare::File)
        end
      end

      it 'returns empty list if those files don`t exist' do
        VCR.use_cassette('rest_file_batch_delete_fail') do
          uuids = ['nonexistent', 'another_nonexistent']
          response = File.batch_delete(uuids)
          expect(response).to be_empty
        end
      end
    end
  end
end
