require 'spec_helper'

module Uploadcare
  RSpec.describe Uploader do
    subject { Uploader }
    let!(:file) { ::File.open('spec/fixtures/kitten.jpeg') }
    let!(:another_file) { ::File.open('spec/fixtures/another_kitten.jpeg') }

    describe 'upload' do
      context 'multiple' do
        it 'returns a hash of filenames and uids' do
          VCR.use_cassette('upload_upload_many') do
            uploads_list = Uploader.upload([file, another_file])
            expect(uploads_list.files.length).to eq 2
            first_upload = uploads_list.files.first
            expect(first_upload.original_filename).not_to be_empty
            expect(first_upload.uuid).not_to be_empty
          end
        end
      end

      context 'one' do
        it 'returns a file' do
          VCR.use_cassette('upload_upload_one') do
            upload = Uploader.upload(file)
            expect(upload).to be_kind_of(Uploadcare::File)
            expect(upload.size).to eq(file.size)
          end
        end
      end

      context 'from_url' do
        it 'polls server and returns file' do
          VCR.use_cassette('upload_upload_from_url') do
            url = 'https://placekitten.com/2250/2250'
            upload = subject.upload_from_url(url)
            expect(upload.files[0]).to be_kind_of(Uploadcare::File)
          end
        end
      end
    end
  end
end
