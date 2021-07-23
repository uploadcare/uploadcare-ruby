# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    module Conversion
      RSpec.describe Uploadcare::Client::Conversion::VideoConversionClient do
        describe 'successfull conversion' do
          describe 'convert_many' do
            subject { described_class.new.convert_many(array_of_params, **options) }

            shared_examples 'requesting video conversion' do
              it 'returns a convert video response' do
                VCR.use_cassette('video_convert_convert_many') do
                  expect(subject.success?).to be true
                end
              end
            end

            let(:array_of_params) do
              [
                {
                  uuid: 'e30112d7-3a90-4931-b2c5-688cbb46d3ac',
                  size: { resize_mode: 'change_ratio', width: '600', height: '400' },
                  quality: 'best',
                  format: 'ogg',
                  cut: { start_time: '0:0:0.0', length: '0:0:1.0' },
                  thumbs: { N: 2, number: 1 }
                }
              ]
            end
            let(:options) { { store: false } }

            context 'when all params are present' do
              it_behaves_like 'requesting video conversion'
            end

            %i[size quality format cut thumbs].each do |param|
              context "when only :#{param} param is present" do
                let(:arguments) { super().select { |k, _v| [:uuid, param].include?(k) } }

                it_behaves_like 'requesting video conversion'
              end
            end
          end

          describe 'get video conversion status' do
            subject { described_class.new.get_conversion_status(token) }

            let(:token) { '911933811' }

            it 'returns a video conversion status data' do
              VCR.use_cassette('video_convert_get_status') do
                expect(subject.success?).to be true
              end
            end
          end
        end

        describe 'conversion with error' do
          shared_examples 'requesting video conversion' do
            it 'raises a conversion error' do
              VCR.use_cassette('video_convert_convert_many_with_error') do
                expect { subject }.to raise_error(
                  Uploadcare::Exception::ConversionError, message
                )
              end
            end
          end

          describe 'convert_many' do
            subject { described_class.new.convert_many(array_of_params, **options) }

            let(:array_of_params) do
              [
                {
                  uuid: 'e30112d7-3a90-4931-b2c5-688cbb46d3ac',
                  size: { resize_mode: 'change_ratio' },
                  quality: 'best',
                  format: 'ogg',
                  cut: { start_time: '0:0:0.0', length: '0:0:1.0' },
                  thumbs: { N: 2, number: 1 }
                }
              ]
            end
            let(:options) { { store: false } }

            context 'when no width and height are provided' do
              let(:message) { /CDN Path error/ }

              it_behaves_like 'requesting video conversion'
            end
          end
        end
      end
    end
  end
end
