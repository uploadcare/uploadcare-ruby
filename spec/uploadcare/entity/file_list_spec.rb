require 'spec_helper'

module Uploadcare
  RSpec.describe FileList do
    it 'responds to expected methods' do
      expect(FileList).to respond_to(:file_list)
    end

    it 'represents a file as entity' do
      VCR.use_cassette('rest_file_list') do
        file_list = FileList.file_list
        expect(file_list).to respond_to(:next, :previous, :results, :total)
      end
    end
  end
end
