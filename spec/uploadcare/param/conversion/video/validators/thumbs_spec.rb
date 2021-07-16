# frozen_string_literal: true

require 'spec_helper'
require 'param/conversion/video/validators/thumbs'
require 'exception/validation_error'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          RSpec.describe Uploadcare::Param::Conversion::Video::Validators::Thumbs do
            subject { described_class.call(n: n, number: number) }

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

            before { stub_const("#{described_class}::VALID_N_RANGE", 1..2) }

            context 'when validate thumbs' do
              context 'and when validation is passed' do
                [1, '2'].each do |thumbs|
                  context "passes thumbs validation with valid 'N' set to #{thumbs}" do
                    let(:n) { thumbs }
                    let(:number) { 0 }

                    it_behaves_like 'validation is passed'
                  end
                end
              end

              context 'and when validation is failed' do
                let(:number) { 0 }

                context 'fails thumbs validation with the invalid "thumbs"' do
                  let(:n) { 3 }

                  it_behaves_like 'validation is failed'
                end

                context 'fails thumbs validation with the blank "thumbs"' do
                  let(:n) { nil }

                  it_behaves_like 'validation is failed'
                end
              end
            end

            context 'when validate number' do
              let(:n) { 2 }

              context 'and when validation is passed' do
                context 'passes thumbs validation with valid "number"' do
                  [0, '1'].each do |number|
                    context "passes thumbs validation with valid 'number' set to #{number}" do
                      let(:number) { number }

                      it_behaves_like 'validation is passed'
                    end
                  end
                end
              end

              context 'and when validation is failed' do
                context 'fails thumbs validation with the invalid "number"' do
                  let(:number) { n }

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
