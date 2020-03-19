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
        it 'returns a hash of filenames and uids' do
          VCR.use_cassette('upload_upload_many') do
            uploads_list = subject.upload([file, another_file])
            expect(uploads_list.length).to eq 2
            first_upload = uploads_list.first
            expect(first_upload.original_filename).not_to be_empty
            expect(first_upload.uuid).not_to be_empty
          end
        end

        describe 'upload_one' do
          it 'returns a file' do
            VCR.use_cassette('upload_upload_one') do
              upload = subject.upload(file)
              expect(upload).to be_kind_of(Uploadcare::Entity::File)
              expect(upload.size).to eq(file.size)
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

        describe 'upload_big_file' do
          it 'polls server and returns array of files' do
            VCR.use_cassette('upload_multipart_upload') do
              # Minimum size for size to be valid for multiupload is 10 mb
              Uploadcare.config.multipart_size_threshold = 10 * 1024 * 1024
              file = subject.upload(big_file)
              expect(file).to be_kind_of(Uploadcare::Entity::File)
              expect(file.uuid).not_to be_empty
            end
          end
        end
      end
    end
  end
end
