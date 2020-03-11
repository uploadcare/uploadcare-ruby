# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    module MultipartUpload
      RSpec.describe ChunksClient do
        subject { ChunksClient.new }
        # Replace this file with actual big file when rewriting fixtures
        let!(:big_file) { ::File.open('spec/fixtures/big.jpeg') }

        describe 'upload_parts' do
          it 'returns raw document part data' do
            VCR.use_cassette('amazon_upload') do
              stub = stub_request(:put, /uploadcare.s3-accelerate.amazonaws.com/)
              start_response = MultipartUploadClient.new.upload_start(big_file)
              upload_response = subject.upload_chunks(big_file, start_response.success[:parts])
              expect(stub).to have_been_requested.at_least_times(3)
            end
          end
        end
      end
    end
  end
end
