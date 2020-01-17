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

    describe 'info' do
      it 'shows insider info about that file' do
        VCR.use_cassette('file_info') do
          uid = '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
          file = Uploadcare::File.info(uid)
          expect(file).to be_a_kind_of(Uploadcare::File)
          expect(file).not_to be_empty
        end
      end
    end

    describe 'copy' do
      it 'makes a copy of a file' do
        VCR.use_cassette('rest_file_copy') do
          uid = '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
          file = Uploadcare::File.copy(source: uid)
        end
      end

      it 'accepts other arguments' do
        VCR.use_cassette('rest_file_copy_arg') do
          uid = '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
          response = Uploadcare::File.copy(source: uid, target: 'nowhere')
          expect(response[:body].to_s).to include('Project has no storage with provided name.')
        end
      end
    end
  end
end
