# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Entity
    RSpec.describe Uploader do
      subject { Uploadcare::Entity::Uploader }
      let!(:file) { ::File.open('spec/fixtures/kitten.jpeg') }
      let!(:another_file) { ::File.open('spec/fixtures/another_kitten.jpeg') }
      let!(:big_file) { ::File.open('spec/fixtures/big.jpeg') }

      describe 'upload_many' do
        it 'returns a hash of filenames and uids', :aggregate_failures do
          VCR.use_cassette('upload_upload_many') do
            uploads_list = subject.upload([file, another_file])
            expect(uploads_list.length).to eq 2
            first_upload = uploads_list.first
            expect(first_upload.original_filename).not_to be_empty
            expect(first_upload.uuid).not_to be_empty
          end
        end

        describe 'upload_one' do
          it 'returns a file', :aggregate_failures do
            VCR.use_cassette('upload_upload_one') do
              upload = subject.upload(file)
              expect(upload).to be_kind_of(Uploadcare::Entity::File)
              expect(file.path).to end_with(upload.original_filename.to_s)
              expect(file.size).to eq(upload.size)
            end
          end

          context 'when the secret key is missing' do
            it 'returns a file without details', :aggregate_failures do
              Uploadcare.config.secret_key = nil

              VCR.use_cassette('upload_upload_one_without_secret_key') do
                upload = subject.upload(file)
                expect(upload).to be_kind_of(Uploadcare::Entity::File)
                expect(file.path).to end_with(upload.original_filename.to_s)
                expect(file.size).to eq(upload.size)
              end
            end
          end
        end

        describe 'upload_from_url' do
          it 'polls server and returns array of files' do
            VCR.use_cassette('upload_upload_from_url') do
              url = 'https://placekitten.com/2250/2250'
              upload = subject.upload(url)
              expect(upload[0]).to be_kind_of(Uploadcare::Entity::File)
            end
          end
        end

        describe 'multipart_upload' do
          let!(:some_var) { nil }

          it 'uploads a file', :aggregate_failures do
            VCR.use_cassette('upload_multipart_upload') do
              # Minimal size for file to be valid for multipart upload is 10 mb
              Uploadcare.config.multipart_size_threshold = 10 * 1024 * 1024
              expect(some_var).to receive(:to_s).at_least(:once).and_call_original
              file = subject.multipart_upload(big_file) { some_var }
              expect(file).to be_kind_of(Uploadcare::Entity::File)
              expect(file.uuid).not_to be_empty
            end
          end
        end

        describe 'get_upload_from_url_status' do
          it 'gets a status of upload-from-URL' do
            VCR.use_cassette('upload_get_upload_from_url_status') do
              token = '0313e4e2-f2ca-4564-833b-4f71bc8cba27'
              status_info = subject.get_upload_from_url_status(token).success
              expect(status_info[:status]).to eq 'success'
            end
          end
        end
      end

      describe 'file_info' do
        it 'returns file info without the secret key', :aggregate_failures do
          uuid = 'a7f9751a-432b-4b05-936c-2f62d51d255d'

          VCR.use_cassette('upload_file_info') do
            file_info = subject.file_info(uuid).success
            expect(file_info[:original_filename]).not_to be_empty
            expect(file_info[:size]).to be >= 0
            expect(file_info[:uuid]).to eq uuid
          end
        end
      end
    end
  end
end
