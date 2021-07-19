# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Entity
    RSpec.describe VideoConverter do
      subject { Uploadcare::Entity::VideoConverter }

      describe 'convert_many' do
        shared_examples 'converts videos' do
          it 'returns a result with video data', :aggregate_failures do
            VCR.use_cassette('video_convert_convert_many') do
              response_value = subject.convert(array_of_params, **options)
              result = response_value[:result].first

              expect(response_value[:problems]).to be_empty
              expect(result[:uuid]).not_to be_nil

              [video_params[:uuid], :size, :quality, :format, :cut, :thumbs].each do |param|
                expect(result[:original_source]).to match(param.to_s)
              end
            end
          end
        end

        let(:array_of_params) { [video_params] }
        let(:video_params) do
          {
            uuid: 'e30112d7-3a90-4931-b2c5-688cbb46d3ac',
            size: { resize_mode: 'change_ratio', width: '600', height: '400' },
            quality: 'best',
            format: 'ogg',
            cut: { start_time: '0:0:0.0', length: '0:0:1.0' },
            thumbs: { thumbs_n: 2, number: 1 }
          }
        end
        let(:options) { { store: false } }

        context 'when all params are present' do
          it_behaves_like 'converts videos'
        end

        %i[size quality format cut thumbs].each do |param|
          context "when only :#{param} param is present" do
            let(:arguments) { super().select { |k, _v| [:uuid, param].include?(k) } }

            it_behaves_like 'converts videos'
          end
        end
      end
    end
  end
end
