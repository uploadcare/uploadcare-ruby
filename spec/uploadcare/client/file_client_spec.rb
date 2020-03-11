# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe FileClient do
      subject { FileClient.new }

      describe 'info' do
        it 'shows insider info about that file' do
          VCR.use_cassette('rest_file_info') do
            uuid = '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
            file = subject.info(uuid)
            expect(file.value![:uuid]).to eq(uuid)
          end
        end

        it 'shows nothing on invalid file' do
          VCR.use_cassette('rest_file_info_fail') do
            uuid = 'nonexistent'
            expect { subject.info(uuid) }.to raise_error(RequestError)
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
            expect { subject.copy(source: uuid, target: 'nowhere') }.to raise_error(RequestError,
              'Project has no storage with provided name.')
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
    end
  end
end
