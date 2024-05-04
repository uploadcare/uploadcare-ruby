# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Entity
    module Conversion
      RSpec.describe DocumentConverter do
        subject { Uploadcare::DocumentConverter }

        describe 'convert_many' do
          shared_examples 'converts documents' do
            it 'returns a result with document data', :aggregate_failures do
              VCR.use_cassette('document_convert_convert_many') do
                response_value = subject.convert(params, **options).success
                result = response_value[:result].first

                expect(response_value[:problems]).to be_empty
                expect(result[:uuid]).not_to be_nil

                [doc_params[:uuid], :format, :page].each do |param|
                  expect(result[:original_source]).to match(param.to_s)
                end
              end
            end
          end

          let(:doc_params) do
            {
              uuid: 'a4b9db2f-1591-4f4c-8f68-94018924525d',
              format: 'png',
              page: 1
            }
          end
          let(:options) { { store: false } }

          context 'when sending params as an Array' do
            let(:params) { [doc_params] }

            it_behaves_like 'converts documents'
          end

          context 'when sending params as a Hash' do
            let(:params) { doc_params }

            it_behaves_like 'converts documents'
          end
        end

        describe 'get video conversion status' do
          let(:token) { '21120333' }

          it 'returns a document conversion status data', :aggregate_failures do
            VCR.use_cassette('document_convert_get_status') do
              response_value = subject.status(token).success

              expect(response_value[:status]).to eq 'finished'
              expect(response_value[:error]).to be_nil
              expect(response_value[:result].keys).to contain_exactly(:uuid)
            end
          end
        end

        describe 'info' do
          it 'shows info about that document' do
            VCR.use_cassette('document_convert_info') do
              uuid = 'cd7a51d4-9776-4749-b749-c9fc691891f1'
              response = subject.info(uuid)
              expect(response.value!.has_key?(:format)).to be_truthy
              document_formats = response.value![:format]
              expect(document_formats.has_key?(:conversion_formats)).to be_truthy
            end
          end
        end
      end
    end
  end
end
