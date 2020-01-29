# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe ChunksClient do
    subject { ChunksClient.new }
    # Replace this file with actual big file when rewriting fixtures
    let!(:big_file) { ::File.open('spec/fixtures/big.jpeg') }

    describe 'upload_parts' do
      it 'returns raw document part data' do
        VCR.use_cassette('amazon_upload') do
          start_response = MultipartUploadClient.new.upload_start(big_file)
          upload_response = subject.upload_chunks(big_file, start_response.success[:parts])
          expect(upload_response.to_s).to include('https://uploadcare.s3-accelerate.amazonaws.com')
        end
      end
    end
  end
end
