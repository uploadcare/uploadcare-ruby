# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe Api do
    subject { Api.new }

    it 'responds to expected REST methods' do
      %i[file file_list store_files delete_files project].each do |method|
        expect(subject).to respond_to(method)
      end
    end

    it 'responds to expected Upload methods' do
      %i[upload upload_files upload_url].each do |method|
        expect(subject).to respond_to(method)
      end
    end

    it 'views file info' do
      VCR.use_cassette('rest_file_info') do
        uuid = '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
        file = subject.file(uuid)
        expect(file.uuid).to eq(uuid)
      end
    end
  end
end
