# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe File do
    subject { File }
    it 'responds to expected methods' do
      expect(subject).to respond_to(:info, :copy, :delete, :store)
    end

    it 'represents a file as entity' do
      VCR.use_cassette('file_info') do
        uuid = '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
        file = subject.info(uuid)
        expect(file).to be_a_kind_of(subject)
        expect(file).to respond_to(:image_info, :datetime_uploaded, :uuid, :url, :size, :original_filename)
        expect(file.uuid).to eq(uuid)
      end
    end

    it 'raises error for nonexistent file' do
      VCR.use_cassette('rest_file_info_fail') do
        uuid = 'nonexistent'
        expect { subject.info(uuid) }.to raise_error(RequestError)
      end
    end

    it 'raises error when trying to delete nonexistent file' do
      VCR.use_cassette('rest_file_delete_nonexistent') do
        uuid = 'nonexistent'
        expect { subject.delete(uuid) }.to raise_error(RequestError)
      end
    end
  end
end
