# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe FileClient do
      subject { FileClient.new }

      describe 'info' do
        it 'shows insider info about that file' do
          VCR.use_cassette('rest_file_info') do
            uuid = '2e17f5d1-d423-4de6-8ee5-6773cc4a7fa6'
            file = subject.info(uuid)
            expect(file.value![:uuid]).to eq(uuid)
          end
        end

        it 'show raise argument error if public_key is blank' do
          Uploadcare.config.public_key = ''
          VCR.use_cassette('rest_file_info') do
            uuid = '2e17f5d1-d423-4de6-8ee5-6773cc4a7fa6'
            expect { subject.info(uuid) }.to raise_error(AuthError, 'Public Key is blank.')
          end
        end

        it 'show raise argument error if secret_key is blank' do
          Uploadcare.config.secret_key = ''
          VCR.use_cassette('rest_file_info') do
            uuid = '2e17f5d1-d423-4de6-8ee5-6773cc4a7fa6'
            expect { subject.info(uuid) }.to raise_error(AuthError, 'Secret Key is blank.')
          end
        end

        it 'show raise argument error if secret_key is nil' do
          Uploadcare.config.secret_key = nil
          VCR.use_cassette('rest_file_info') do
            uuid = '2e17f5d1-d423-4de6-8ee5-6773cc4a7fa6'
            expect { subject.info(uuid) }.to raise_error(AuthError, 'Secret Key is blank.')
          end
        end

        it 'supports extra params like include' do
          VCR.use_cassette('rest_file_info') do
            uuid = '640fe4b7-7352-42ca-8d87-0e4387957157'
            file = subject.info(uuid, { include: 'appdata' })
            expect(file.value![:uuid]).to eq(uuid)
            expect(file.value![:appdata]).not_to be_empty
          end
        end

        it 'shows nothing on invalid file' do
          VCR.use_cassette('rest_file_info_fail') do
            uuid = 'nonexistent'
            expect { subject.info(uuid) }.to raise_error(RequestError)
          end
        end
      end

      describe 'delete' do
        it 'deletes a file' do
          VCR.use_cassette('rest_file_delete') do
            uuid = '158e7c82-8246-4017-9f17-0798e18c91b0'
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
