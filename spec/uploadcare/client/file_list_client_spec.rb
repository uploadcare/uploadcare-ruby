require 'spec_helper'

module Uploadcare
  RSpec.describe FileListClient do
    subject { FileListClient.new }

    describe 'file_list' do
      it 'returns paginated list with files data' do
        VCR.use_cassette('rest_file_list') do
          file_list = subject.file_list.value!
          expected_fields = %i[total per_page results]
          expected_fields.each do |field|
            expect(file_list[field]).not_to be_nil
          end
        end
      end
    end
  end
end
