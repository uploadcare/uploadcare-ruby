# frozen_string_literal: true

require 'spec_helper'
require 'param/conversion/video/validators/format'
require 'exception/validation_error'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          RSpec.describe Uploadcare::Param::Conversion::Video::Validators::Format do
            subject { described_class.call(format: format) }

            before do
              stub_const(
                "#{described_class}::SUPPORTED_OPTIONS",
                OpenStruct.new(formats: %w[webm ogg mp4])
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

            context 'when validate format' do
              context 'and when validation is passed' do
                described_class::SUPPORTED_OPTIONS.formats.each do |format|
                  context "passes format validation with format set to #{format}" do
                    let(:format) { format }

                    it_behaves_like 'validation is passed'
                  end
                end
              end

              context 'and when validation is failed' do
                context 'fails format validation with the invalid "format"' do
                  let(:format) { 'some_invalid_format' }

                  it_behaves_like 'validation is failed'
                end

                context 'fails format validation with the blank "format"' do
                  let(:format) { nil }

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
