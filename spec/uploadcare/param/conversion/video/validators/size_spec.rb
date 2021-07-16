# frozen_string_literal: true

require 'spec_helper'
require 'param/conversion/video/validators/size'
require 'exception/validation_error'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          RSpec.describe Uploadcare::Param::Conversion::Video::Validators::Size do
            subject { described_class.call(resize_mode: resize_mode, width: width, height: height) }

            before do
              stub_const(
                "#{described_class}::SUPPORTED_OPTIONS",
                OpenStruct.new(resize_modes: %w[preserve_ratio change_ratio scale_crop add_padding])
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

            context 'when validate resize_mode' do
              let(:width) { 600 }
              let(:height) { 600 }

              context 'and when validation is passed' do
                described_class::SUPPORTED_OPTIONS.resize_modes.each do |resize_mode|
                  context "passes size validation with resize_mode set to #{resize_mode}" do
                    it_behaves_like 'validation is passed' do
                      let(:resize_mode) { resize_mode }
                    end
                  end
                end
              end

              context 'and when validation is failed' do
                context 'fails size validation with the invalid "resize_mode"' do
                  let(:resize_mode) { 'some_invalid_resize_mode' }

                  it_behaves_like 'validation is failed'
                end

                context 'fails size validation with the blank "resize_mode"' do
                  let(:resize_mode) { nil }

                  it_behaves_like 'validation is failed'
                end
              end
            end

            context 'when validate width and height' do
              let(:resize_mode) { 'preserve_ratio' }

              context 'and when validation is passed' do
                context 'and when params are strings' do
                  let(:width) { '720' }
                  let(:height) { '540' }

                  it_behaves_like 'validation is passed'
                end

                context 'and when width is blank and height is present' do
                  let(:width) { nil }
                  let(:height) { '540' }

                  it_behaves_like 'validation is passed'
                end

                context 'and when width is present and height is blank' do
                  let(:width) { '540' }
                  let(:height) { nil }

                  it_behaves_like 'validation is passed'
                end
              end

              context 'and when validation is failed' do
                context 'and when width and height are blank' do
                  let(:width) { nil }
                  let(:height) { nil }

                  it_behaves_like 'validation is failed'
                end

                context 'and when width is not divisible by 4' do
                  let(:width) { '10' }
                  let(:height) { '540' }

                  it_behaves_like 'validation is failed'
                end

                context 'and when height is not divisible by 4' do
                  let(:width) { '540' }
                  let(:height) { '10' }

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
