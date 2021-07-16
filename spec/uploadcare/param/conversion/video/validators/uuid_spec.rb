# frozen_string_literal: true

require 'spec_helper'
require 'param/conversion/video/validators/uuid'
require 'exception/validation_error'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          RSpec.describe Uploadcare::Param::Conversion::Video::Validators::Uuid do
            subject { described_class.call(uuid: uuid) }

            before do
              stub_const(
                "#{described_class}::UUID_REGEX",
                /\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b/.freeze
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

            context 'when validate store' do
              context 'and when validation is passed' do
                %w[b054825b-17f2-4746-9f0c-8feee4d81ca1 35af2b1b-fce6-408e-bee5-6ec3c59bb660].each do |value|
                  context "passes uuid validation with uuid set to #{value}" do
                    let(:uuid) { value }

                    it_behaves_like 'validation is passed'
                  end
                end
              end

              context 'and when validation is failed' do
                %w[
                    b054825b1-17f2-4746-9f0c-8feee4d81ca1
                    35af2b1-fce6-408e-bee5-6ec3c59bb660
                    b054825b-17f2a-4746-9f0c-8feee4d81ca1
                    b054825b-17f-4746-9f0c-8feee4d81ca1
                    b054825b-17f2-47463-9f0c-8feee4d81ca1
                    b054825b-17f2-474-9f0c-8feee4d81ca1
                    b054825b-17f2-4746-9f0c1-8feee4d81ca1
                    b054825b-17f2-4746-90c-8feee4d81ca1
                    b054825b-17f2-4746-9f0c-8feee4d81ca11
                    b054825b-17f2-4746-9f0c-8feee4d81ca
                  ].each do |value|
                  context "fails uuid validation with uuid set to #{value}" do
                    let(:uuid) { value }

                    it_behaves_like 'validation is failed'
                  end
                end

                context 'fails uuid validation with the blank "uuid"' do
                  let(:uuid) { nil }

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
