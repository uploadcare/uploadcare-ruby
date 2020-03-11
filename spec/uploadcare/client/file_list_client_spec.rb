# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe FileListClient do
      subject { FileListClient.new }

      describe 'file_list' do
        it 'returns paginated list with files data' do
          VCR.use_cassette('rest_file_list') do
            file_list = subject.file_list.value!
            expected_fields = %i[total per_page results]
            expected_fields.each do |field|
              expect(file_list[field]).not_to be_nil
            end
          end
        end

        it 'processes options' do
          VCR.use_cassette('rest_file_list_limited') do
            first_page = subject.file_list(limit: 2).value!
            second_page = subject.file_list(limit: 2).value!
            expect(first_page[:per_page]).to eq(2)
            expect(first_page[:results].length).to eq(2)
            expect(first_page[:results]).not_to eq(second_page[:result])
          end
        end
      end

      describe 'batch_store' do
        it 'changes files` statuses to stored' do
          VCR.use_cassette('rest_file_batch_store') do
            uuids = ['e9a9f291-cc52-4388-bf65-9feec1c75ff9', 'c724feac-86f7-447c-b2d6-b0ced220173d']
            response = subject.batch_store(uuids)
            response_value = response.value!
            expect(uuids.all? { |uuid| response_value.to_s.include?(uuid) }).to be true
          end
        end

        context 'invalid uuids' do
          it 'returns a list of problems' do
            VCR.use_cassette('rest_file_batch_store_fail') do
              uuids = %w[nonexistent other_nonexistent]
              response = subject.batch_store(uuids)
              expect(response.success[:files]).to be_nil
              expect(response.success[:problems]).not_to be_empty
            end
          end
        end
      end

      describe 'batch_delete' do
        it 'changes files` statuses to stored' do
          VCR.use_cassette('rest_file_batch_delete') do
            uuids = ['935ff093-a5cf-48c5-81cf-208511bac6e6', '63be5a6e-9b6b-454b-8aec-9136d5f83d0c']
            response = subject.batch_delete(uuids)
            response_value = response.value!
            expect(response_value[:result][0][:datetime_removed]).not_to be_empty
          end
        end

        context 'invalid uuids' do
          it 'returns a list of problems' do
            VCR.use_cassette('rest_file_batch_delete_fail') do
              uuids = %w[nonexistent other_nonexistent]
              response = subject.batch_delete(uuids)
              expect(response.success[:files]).to be_nil
              expect(response.success[:problems]).not_to be_empty
            end
          end
        end
      end
    end
  end
end
