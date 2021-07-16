# frozen_string_literal: true

require 'spec_helper'
require 'param/conversion/video/validators/store'
require 'exception/validation_error'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          RSpec.describe Uploadcare::Param::Conversion::Video::Validators::Store do
            subject { described_class.call(store: store) }

            let(:valid_values) do
              {
                nil => nil,
                true => '1',
                false => '0'
              }
            end

            before do
              stub_const("#{described_class}::VALID_VALUES", valid_values)
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

            context 'when validate store' do
              context 'and when validation is passed' do
                [nil, true, false].each do |value|
                  context "passes store validation with store set to #{value}" do
                    let(:store) { value }

                    it_behaves_like 'validation is passed'
                  end
                end
              end

              context 'and when validation is failed' do
                context 'fails store validation with the invalid "store"' do
                  let(:store) { 'some_invalid_value' }

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
