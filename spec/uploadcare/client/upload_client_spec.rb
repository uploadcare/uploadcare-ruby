# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe UploadClient do
    subject { UploadClient.new }
    let!(:file) { ::File.open('spec/fixtures/kitten.jpeg') }
    let!(:another_file) { ::File.open('spec/fixtures/another_kitten.jpeg') }

    before do
      BASE_REQUEST_SLEEP_SECONDS = 0
      MAX_REQUEST_SLEEP_SECONDS = 0.1
    end

    describe 'upload' do
      it 'uploads a file' do
        VCR.use_cassette('upload_upload') do
          response = subject.upload_many([file])
          expect(response.success?).to be true
        end
      end

      it 'uploads multiple files in one request' do
        VCR.use_cassette('upload_upload_many') do
          response = subject.upload_many([file, another_file])
          expect(response.success?).to be true
          result = response.success
          expect(result.length).to eq 2
        end
      end
    end

    describe 'upload_from_url' do
      context 'async' do
        it 'returns token' do
          VCR.use_cassette('upload_upload_from_url_async') do
            url = 'https://placekitten.com/225/225'
            response = subject.upload_from_url(url, async: true)
            expect(response.value![:token]).not_to be_empty
          end
        end
      end

      context 'normal' do
        it 'polls server and returns file' do
          VCR.use_cassette('upload_upload_from_url') do
            url = 'https://placekitten.com/2250/2250'
            response = subject.upload_from_url(url)
            expect(response.success[:files][0][:original_filename]).to eq('2250')
          end
        end
      end

      context 'with progress response' do
        it 'processes progress response normally; continues waiting for it' do
          VCR.use_cassette('upload_upload_from_url_progress') do
            url = 'https://placekitten.com/2250/2250'
            response = subject.upload_from_url(url)
            expect(response.success[:files][0][:original_filename]).to eq('2250')
          end
        end
      end

      context 'invalid file' do
        it 'returns token' do
          VCR.use_cassette('upload_upload_invalid') do
            url = 'https://example.com/foo/bar'
            response = subject.upload_from_url(url)
            expect(response.value![:status]).to eq 'error'
          end
        end
      end
    end
  end
end
