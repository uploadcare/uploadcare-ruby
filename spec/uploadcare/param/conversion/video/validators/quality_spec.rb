# frozen_string_literal: true

require 'spec_helper'
require 'param/conversion/video/validators/quality'
require 'exception/validation_error'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          RSpec.describe Uploadcare::Param::Conversion::Video::Validators::Quality do
            subject { described_class.call(quality: quality) }

            before do
              stub_const(
                "#{described_class}::SUPPORTED_OPTIONS",
                OpenStruct.new(qualities: %w[normal better best lighter lightest])
              )
            end

            shared_examples 'validation is passed' do
              it "passes validation" do
                expect { subject }.not_to raise_error
              end
            end

            shared_examples 'validation is failed' do
              it "fails validation" do
                expect { subject }.to raise_error(Uploadcare::Exception::ValidationError)
              end
            end

            context 'when validate quality' do
              context 'and when validation is passed' do
                described_class::SUPPORTED_OPTIONS.qualities.each do |quality|
                  context "passes quality validation with quality set to #{quality}" do
                    let(:quality) { quality }

                    it_behaves_like 'validation is passed'
                  end
                end
              end

              context 'and when validation is failed' do
                context 'fails quality validation with the invalid "quality"' do
                  let(:quality) { 'some_invalid_quality' }

                  it_behaves_like 'validation is failed'
                end

                context 'fails quality validation with the blank "quality"' do
                  let(:quality) { nil }

                  it_behaves_like 'validation is failed'
                end
              end
            end
          end
        end
      end
    end
  end
end
