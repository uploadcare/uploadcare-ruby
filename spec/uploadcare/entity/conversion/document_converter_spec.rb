# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Entity
    module Conversion
      RSpec.describe DocumentConverter do
        subject { Uploadcare::DocumentConverter }

        describe 'convert' do
          shared_examples 'converts documents' do |multipage: false, group: false|
            it 'returns a result with document data', :aggregate_failures do
              response_value = subject.convert(params, **options).success
              result = response_value[:result].first

              expect(response_value[:problems]).to be_empty
              expect(result[:uuid]).not_to be_nil

              [doc_params[:uuid], :format].each do |param|
                expect(result[:original_source]).to match(param.to_s)
              end
              expect(result[:original_source]).to match('page') if doc_params[:page]

              next unless multipage

              info_response_values = subject.info(doc_params[:uuid]) # get info about that document
              if group
                expect(
                  info_response_values.success.dig(:format, :converted_groups, doc_params[:format].to_sym)
                ).not_to be_empty
              else
                expect(info_response_values.success.dig(:format, :converted_groups)).to be_nil
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

          context 'when sending params as an Array', vcr: 'document_convert_convert_many' do
            let(:params) { [doc_params] }

            it_behaves_like 'converts documents'
          end

          context 'when sending params as a Hash', vcr: 'document_convert_convert_many' do
            let(:params) { doc_params }

            it_behaves_like 'converts documents'
          end

          # Ref: https://uploadcare.com/docs/transformations/document-conversion/#multipage-conversion
          describe 'multipage conversion' do
            context 'when not saved in group', vcr: 'document_convert_convert_multipage_zip' do
              let(:doc_params) do
                {
                  uuid: 'd95309eb-50bd-4594-bd7a-950011578480',
                  format: 'jpg'
                }
              end
              let(:options) { { store: '1', save_in_group: '0' } }
              let(:params) { doc_params }

              it_behaves_like 'converts documents', { multipage: true, group: false }
            end

            context 'when saved in group', vcr: 'document_convert_convert_multipage_group' do
              let(:doc_params) do
                {
                  uuid: '23d29586-713e-4152-b400-05fb54730453',
                  format: 'jpg'
                }
              end
              let(:options) { { store: '0', save_in_group: '1' } }
              let(:params) { doc_params }

              it_behaves_like 'converts documents', { multipage: true, group: true }
            end
          end
        end

        describe 'get document conversion status' do
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
              expect(response.value!.key?(:format)).to be_truthy
              document_formats = response.value![:format]
              expect(document_formats.key?(:conversion_formats)).to be_truthy
            end
          end
        end
      end
    end
  end
end
