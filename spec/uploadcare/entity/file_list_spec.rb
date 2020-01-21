require 'spec_helper'

module Uploadcare
  RSpec.describe FileList do
    it 'responds to expected methods' do
      %i[file_list].each do |method|
        expect(FileList).to respond_to(method)
      end
    end

    it 'represents a file as entity' do
      VCR.use_cassette('rest_file_list') do
        file_list = FileList.file_list
        %i[next previous results total].each do |method|
          expect(file_list).to respond_to(method)
        end
      end
    end
  end
end
