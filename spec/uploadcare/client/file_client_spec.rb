require 'spec_helper'

module Uploadcare
  RSpec.describe FileClient do
    subject { FileClient.new }

    describe 'index' do
      before do
        VCR.use_cassette('file') do
          @files = subject.index.value!
        end
      end

      it 'lists a bunch of files' do
        expect(@files.length).to eq(3)
      end
    end

    describe 'info' do
      it 'shows insider info about that file' do
        VCR.use_cassette('rest_file_info') do
          uuid = '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
          file = subject.info(uuid)
          expect(file.value![:uuid]).to eq(uuid)
        end
      end
    end

    describe 'copy' do
      it 'makes a copy of a file' do
        VCR.use_cassette('rest_file_copy') do
          uuid = '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
          response = subject.copy(source: uuid)
          new_uuid = response.value!.dig(:result, :uuid)
          expect(new_uuid).to be_a_kind_of(String)
          expect(new_uuid).not_to eq(uuid)
        end
      end

      it 'accepts other arguments' do
        VCR.use_cassette('rest_file_copy_arg') do
          uuid = '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
          response = subject.copy(source: uuid, target: 'nowhere')
          expect(response.to_s).to include('Project has no storage with provided name.')
        end
      end
    end

    describe 'delete' do
      it 'deletes a file' do
        VCR.use_cassette('rest_file_delete') do
          uuid = 'e9a9f291-cc52-4388-bf65-9feec1c75ff9'
          response = subject.delete(uuid)
          response_value = response.value!
          expect(response_value[:datetime_removed]).not_to be_empty
          expect(response_value[:uuid]).to eq(uuid)
        end
      end
    end

    describe 'store' do
      it 'changes file`s status to stored' do
        VCR.use_cassette('rest_file_store') do
          uuid = 'e9a9f291-cc52-4388-bf65-9feec1c75ff9'
          response = subject.store(uuid)
          expect(response.value![:datetime_stored]).not_to be_empty
        end
      end
    end

    describe 'batch_store' do
      it 'changes files` statuses to stored' do
        VCR.use_cassette('rest_file_batch_store') do
          uuids = ['e9a9f291-cc52-4388-bf65-9feec1c75ff9', 'c724feac-86f7-447c-b2d6-b0ced220173d']
          response = subject.batch_store(uuids)
          response_value = response.value!
          expect(response_value[:problems]).to be_empty
          expect(uuids.all? { |uuid| response_value[:result].to_s.include?(uuid) }).to be true
        end
      end

      it 'changes files` statuses to stored' do
        VCR.use_cassette('rest_file_batch_store_fail') do
          uuids = ['nonexistent', 'nonexistent', 'other_nonexistent']
          response = subject.batch_store(uuids)
          expect(response.value![:problems]).not_to be_empty
        end
      end
    end
  end
end
