# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Entity
    RSpec.describe FileList do
      subject { FileList }

      it 'responds to expected methods' do
        expect(subject).to respond_to(:file_list, :batch_store, :batch_delete)
      end

      it 'represents a file as entity' do
        VCR.use_cassette('rest_file_list') do
          file_list = subject.file_list
          expect(file_list).to respond_to(:next, :previous, :results, :total, :files)
          expect(file_list.meta).to respond_to(:next, :previous, :total, :per_page)
        end
      end

      it 'accepts arguments' do
        VCR.use_cassette('rest_file_list_params') do
          fl_with_params = FileList.file_list(limit: 2, ordering: 'size')
          expect(fl_with_params.meta.per_page).to eq 2
        end
      end

      context 'batch_store' do
        it 'returns a list of stored files' do
          VCR.use_cassette('rest_file_batch_store') do
            uuids = %w[e9a9f291-cc52-4388-bf65-9feec1c75ff9 c724feac-86f7-447c-b2d6-b0ced220173d]
            response = subject.batch_store(uuids)
            expect(response.files.length).to eq 2
            expect(response.files[0]).to be_a_kind_of(Uploadcare::Entity::File)
          end
        end

        it 'returns empty list if those files don`t exist' do
          VCR.use_cassette('rest_file_batch_store_fail') do
            uuids = %w[nonexistent another_nonexistent]
            response = subject.batch_store(uuids)
            expect(response.files).to be_empty
          end
        end
      end

      context 'batch_delete' do
        it 'returns a list of deleted files' do
          VCR.use_cassette('rest_file_batch_delete') do
            uuids = %w[935ff093-a5cf-48c5-81cf-208511bac6e6 63be5a6e-9b6b-454b-8aec-9136d5f83d0c]
            response = subject.batch_delete(uuids)
            expect(response.files.length).to eq 2
            expect(response.files[0]).to be_a_kind_of(Uploadcare::Entity::File)
          end
        end

        it 'returns empty list if those files don`t exist' do
          VCR.use_cassette('rest_file_batch_delete_fail') do
            uuids = %w[nonexistent another_nonexistent]
            response = subject.batch_delete(uuids)
            expect(response.files).to be_empty
          end
        end
      end
    end
  end
end
