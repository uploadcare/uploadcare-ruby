require 'spec_helper'

module Uploadcare
  RSpec.describe Uploader do
    subject { Uploader }
    let!(:file) { ::File.open('spec/fixtures/kitten.jpeg') }
    let!(:another_file) { ::File.open('spec/fixtures/another_kitten.jpeg') }

    describe 'upload' do
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
  end
end
