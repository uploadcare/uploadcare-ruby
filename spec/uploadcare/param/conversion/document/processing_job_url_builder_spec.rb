# frozen_string_literal: true

require 'spec_helper'
require 'param/conversion/document/processing_job_url_builder'

module Uploadcare
  module Param
    module Conversion
      module Document
        RSpec.describe Uploadcare::Param::Conversion::Document::ProcessingJobUrlBuilder do
          subject { described_class.call(**arguments) }

          let(:uuid) { 'b054825b-17f2-4746-9f0c-8feee4d81ca1' }
          let(:arguments) do
            {
              uuid: uuid,
              format: 'png'
            }
          end

          shared_examples 'URL building' do
            it 'builds a URL' do
              expect(subject).to eq expected_url
            end
          end

          context 'when building an URL' do
            context 'and when only the :format param is present' do
              let(:expected_url) do
                "#{uuid}/document/-/format/#{arguments[:format]}/"
              end

              it_behaves_like 'URL building'
            end

            context 'and when :format and :page params are present' do
              let(:arguments) { super().merge(page: 1) }
              let(:expected_url) do
                "#{uuid}/document/-/format/#{arguments[:format]}/-/page/#{arguments[:page]}/"
              end

              it_behaves_like 'URL building'
            end
          end
        end
      end
    end
  end
end
