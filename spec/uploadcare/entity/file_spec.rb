require 'spec_helper'

module Uploadcare
  RSpec.describe File do
    it 'responds to expected methods' do
      %i[index info copy delete store].each do |method|
        expect(File).to respond_to(method)
      end
    end

    it 'represents a file as entity' do
      VCR.use_cassette('file_info') do
        uuid = '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
        file = Uploadcare::File.info(uuid)
        expect(file).to be_a_kind_of(Uploadcare::File)
        file_fields = %i[image_info datetime_uploaded uuid url size original_filename]
        file_fields.each do |method|
          expect(file).to respond_to(method)
        end
        expect(file.uuid).to eq(uuid)
      end
    end

  end
end
