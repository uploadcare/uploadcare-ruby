# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe UploaderClient do
      subject { UploaderClient.new }
      let!(:file) { ::File.open('spec/fixtures/kitten.jpeg') }
      let!(:another_file) { ::File.open('spec/fixtures/another_kitten.jpeg') }

      describe 'upload' do
        it 'uploads a file' do
          VCR.use_cassette('upload_upload') do
            response = subject.upload(file)
            expect(response.success?).to be true
          end
        end

        it 'uploads multiple files in one request' do
          VCR.use_cassette('upload_upload_many') do
            response = subject.upload_many([file, another_file])
            expect(response.success?).to be true
            expect(response.success.length).to eq 2
          end
        end
      end
    end
  end
end
