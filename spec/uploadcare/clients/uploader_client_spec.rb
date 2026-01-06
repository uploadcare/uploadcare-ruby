# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::UploaderClient do
  subject { described_class.new }

  describe 'upload' do
    let(:file) { File.open('spec/fixtures/kitten.jpeg') }
    let(:another_file) { File.open('spec/fixtures/another_kitten.jpeg') }

    it 'uploads a file' do
      VCR.use_cassette('upload_upload') do
        response = subject.upload(file, metadata: { subsystem: 'test' })
        expect(response).to be_a(Hash)
        expect(response.keys.first).to include('.jpeg')
      end
    end

    it 'uploads multiple files in one request' do
      VCR.use_cassette('upload_upload_many') do
        response = subject.upload_many([file, another_file])
        expect(response).to be_a(Hash)
        expect(response.size).to eq(2)
      end
    end
  end
end
