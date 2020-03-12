# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Entity
    RSpec.describe File do
      subject { File }
      it 'responds to expected methods' do
        expect(subject).to respond_to(:info, :copy, :delete, :store)
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

      it 'raises error for nonexistent file' do
        VCR.use_cassette('rest_file_info_fail') do
          uuid = 'nonexistent'
          expect { subject.info(uuid) }.to raise_error(RequestError)
        end
      end

      it 'raises error when trying to delete nonexistent file' do
        VCR.use_cassette('rest_file_delete_nonexistent') do
          uuid = 'nonexistent'
          expect { subject.delete(uuid) }.to raise_error(RequestError)
        end
      end

      describe 'internal_copy' do
        it 'copies file to same project' do
          VCR.use_cassette('rest_file_internal_copy') do
            file = subject.file('35b7fcd7-9bca-40e1-99b1-2adcc21c405d')
            file.local_copy
          end
        end
      end

      describe 'external_copy' do
        it 'copies file to different project' do
          VCR.use_cassette('rest_file_external_copy') do
            file = subject.file('35b7fcd7-9bca-40e1-99b1-2adcc21c405d')
            # I don't have custom storage, but this error recognises what this method tries to do
            expect { file.remote_copy('16d8625b4c5c4a372a8f') }.to raise_error(RequestError, 'Project has no storage with provided name.')
          end
        end
      end

      describe 'uuid' do
        it 'returns uuid, even if only url is defined' do
          file = File.new(url: 'https://ucarecdn.com/35b7fcd7-9bca-40e1-99b1-2adcc21c405d/123.jpg')
          expect(file.uuid).to eq '35b7fcd7-9bca-40e1-99b1-2adcc21c405d'
        end
      end

      describe 'load' do
        it 'performs load request' do
          VCR.use_cassette('file_info') do
            url = 'https://ucarecdn.com/8f64f313-e6b1-4731-96c0-6751f1e7a50a'
            file = File.new(Hashie::Mash.new(url: url))
            file.load
            expect(file.datetime_uploaded).not_to be_nil
          end
        end
      end
    end
  end
end
