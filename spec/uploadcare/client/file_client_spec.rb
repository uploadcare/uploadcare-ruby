require 'spec_helper'

module Uploadcare
  RSpec.describe FileClient do
    it 'makes a request' do
      VCR.use_cassette('file') do
        response = FileClient.new.index
        expect(WebMock).to have_requested(:get, "https://api.uploadcare.com/files/")
      end
    end
  end
end
