
# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    module Conversion
      RSpec.describe DocumentConversionClient do

        describe 'convert_many' do
          subject { described_class.new.convert_many(array_of_params, **options) }

          shared_examples 'requesting documents conversion' do
            it 'returns a convert documents response' do
              VCR.use_cassette('document_convert_convert_many') do
                expect(subject.success?).to be true
              end
            end
          end

          let(:array_of_params) do
            [
              {
                uuid: 'a4b9db2f-1591-4f4c-8f68-94018924525d',
                format: 'png',
                page: 1
              }
            ]
          end
          let(:options) { { store: false } }

          context 'when all params are present' do
            it_behaves_like 'requesting documents conversion'
          end
        end

        describe 'get document conversion status' do
          subject { described_class.new.get_conversion_status(token) }

          let(:token) { '21120333' }

          it 'returns a document conversion status data' do
            VCR.use_cassette('document_convert_get_status') do
              expect(subject.success?).to be true
            end
          end
        end
      end
    end
  end
end
