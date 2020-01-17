require 'spec_helper'

module Uploadcare
  RSpec.describe File do
    describe 'index' do
      before do
        VCR.use_cassette('file') do
          @files = File.index
        end
      end

      it 'lists a bunch of files' do
        expect(@files.length).to eq(3)
        expect(@files.first).to be_a(Uploadcare::File)
      end
    end
  end
end
