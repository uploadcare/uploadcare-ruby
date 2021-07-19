# frozen_string_literal: true

require 'spec_helper'
require 'param/conversion/video/processing_job_url_builder'

module Uploadcare
  module Param
    module Conversion
      module Video
        RSpec.describe Uploadcare::Param::Conversion::Video::ProcessingJobUrlBuilder do
          subject { described_class.call(**arguments) }

          let(:uuid) { 'b054825b-17f2-4746-9f0c-8feee4d81ca1' }
          let(:arguments) do
            {
              uuid: uuid,
              size: { resize_mode: 'preserve_ratio', width: '600', height: '400' },
              quality: 'best',
              format: 'ogg',
              cut: { start_time: '1:1:1.1', length: '2:1:1.1' },
              thumbs: { N: 20, number: 4 }
            }
          end

          shared_examples 'URL building' do
            it 'builds a URL' do
              expect(subject).to eq expected_url
            end
          end

          context 'when building an URL' do
            context 'and when all operations are present' do
              let(:expected_url) do
                "#{uuid}/video/-" \
                "/size/#{arguments[:size][:width]}x#{arguments[:size][:height]}/#{arguments[:size][:resize_mode]}/-" \
                "/quality/#{arguments[:quality]}/-" \
                "/format/#{arguments[:format]}/-" \
                "/cut/#{arguments[:cut][:start_time]}/#{arguments[:cut][:length]}/-" \
                "/thumbs~#{arguments[:thumbs][:N]}/#{arguments[:thumbs][:number]}/"
              end

              it_behaves_like 'URL building'
            end

            context 'and when only the :size operation is present' do
              let(:arguments) { super().select { |k, _v| %i[uuid size].include?(k) } }
              let(:expected_url) do
                "#{uuid}/video/-" \
                "/size/#{arguments[:size][:width]}x#{arguments[:size][:height]}/#{arguments[:size][:resize_mode]}/"
              end

              it_behaves_like 'URL building'
            end

            %i[quality format].each do |param|
              context "and when only the :#{param} operation is present" do
                let(:arguments) { super().select { |k, _v| [:uuid, param].include?(k) } }
                let(:expected_url) { "#{uuid}/video/-/#{param}/#{arguments[param]}/" }

                it_behaves_like 'URL building'
              end
            end

            context 'and when only the :cut operation is present' do
              let(:arguments) { super().select { |k, _v| %i[uuid cut].include?(k) } }
              let(:expected_url) do
                "#{uuid}/video/-/cut/#{arguments[:cut][:start_time]}/#{arguments[:cut][:length]}/"
              end

              it_behaves_like 'URL building'
            end

            context 'and when only the :thumbs operation is present' do
              let(:arguments) { super().select { |k, _v| %i[uuid thumbs].include?(k) } }
              let(:expected_url) do
                "#{uuid}/video/-/thumbs~#{arguments[:thumbs][:N]}/#{arguments[:thumbs][:number]}/"
              end

              it_behaves_like 'URL building'
            end
          end
        end
      end
    end
  end
end
