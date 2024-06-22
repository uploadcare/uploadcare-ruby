# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    module Conversion
      RSpec.describe DocumentConversionClient do
        describe 'successfull conversion' do
          describe 'convert_many' do
            subject { described_class.new.convert_many(array_of_params, **options) }

            shared_examples 'succeeds documents conversion' do
              it 'returns a convert documents response' do
                expect(subject).to be_success
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

            context 'when all params are present', vcr: 'document_convert_convert_many' do
              it_behaves_like 'succeeds documents conversion'
            end

            context 'multipage conversion', vcr: 'document_convert_to_multipage' do
              let(:array_of_params) do
                [
                  {
                    uuid: '23d29586-713e-4152-b400-05fb54730453',
                    format: 'png'
                  }
                ]
              end
              let(:options) { { store: '0', save_in_group: '1' } }

              it_behaves_like 'succeeds documents conversion'
            end
          end

          describe 'get document conversion status' do
            subject { described_class.new.get_conversion_status(token) }

            let(:token) { '21120333' }

            it 'returns a document conversion status data' do
              VCR.use_cassette('document_convert_get_status') do
                expect(subject).to be_success
              end
            end
          end
        end

        describe 'conversion with error' do
          shared_examples 'failed document conversion' do
            it 'raises a conversion error' do
              VCR.use_cassette('document_convert_convert_many_with_error') do
                expect(subject).to be_failure
              end
            end
          end

          describe 'convert_many' do
            subject { described_class.new.convert_many(array_of_params, **options) }

            let(:array_of_params) do
              [
                {
                  uuid: '86c54d9a-3453-4b12-8dcc-49883ae8f084',
                  format: 'jpg',
                  page: 1
                }
              ]
            end
            let(:options) { { store: false } }

            context 'when the target_format is not a supported' do
              let(:message) { /target_format is not a supported/ }

              it_behaves_like 'failed document conversion'
            end
          end
        end
      end
    end
  end
end
