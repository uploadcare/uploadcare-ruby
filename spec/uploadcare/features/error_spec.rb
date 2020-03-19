# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe 'User-friendly errors' do
    # Ideally, this gem should raise errors as they are described in API
    let!(:file) { ::File.open('spec/fixtures/kitten.jpeg') }

    context 'REST API' do
      it 'raises a readable error on failed requests' do
        VCR.use_cassette('rest_file_info_fail') do
          uuid = 'nonexistent'
          expect { Entity::File.info(uuid) }.to raise_error(RequestError, 'Not found.')
        end
      end
    end

    context 'Upload API' do
      # For some reason, upload errors come with status 200;
      # You need to actually read the response to find out that it is in fact an error
      it 'raises readable errors with incorrect 200 responses' do
        VCR.use_cassette('upload_error') do
          Uploadcare.config.public_key = 'baz'
          begin
            Entity::Uploader.upload(file)
          rescue StandardError => err
            expect(err.to_s).to include('UPLOADCARE_PUB_KEY is invalid')
          end
        end
      end
    end
  end
end
