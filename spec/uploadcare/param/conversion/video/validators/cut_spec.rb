# frozen_string_literal: true

require 'spec_helper'
require 'param/conversion/video/validators/cut'
require 'exception/validation_error'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          RSpec.describe Uploadcare::Param::Conversion::Video::Validators::Cut do
            subject { described_class.call(start_time: start_time, length: length) }

            shared_examples 'validation is passed' do
              it 'passes validation' do
                expect { subject }.not_to raise_error
              end
            end

            shared_examples 'validation is failed' do
              it 'fails validation' do
                expect { subject }.to raise_error(Uploadcare::Exception::ValidationError)
              end
            end

            context 'when validate "start_time"' do
              let(:length) { 140 }

              context 'and when validation is passed' do
                %w[1:2:40.535 2:20.0 001:02:40.535 2:30.535 1:2:40.535 3760.1 140 999:59:59.999
                   1:1:1.1].each do |start_time|
                  context "passes cut start_time validation with 'start_time' set to #{start_time}" do
                    let(:start_time) { start_time }

                    it_behaves_like 'validation is passed'
                  end
                end
              end

              context 'and when validation is failed' do
                %w[:2:40.535 1000:20.0 22:64:40.535 2:30.1000 1:2:62.5 string.535 end a:b:v.d].each do |start_time|
                  context "passes cut start_time validation with 'start_time' set to #{start_time}" do
                    let(:start_time) { start_time }

                    it_behaves_like 'validation is failed'
                  end
                end

                context 'fails cut start_time validation with the blank "start_time"' do
                  let(:start_time) { nil }

                  it_behaves_like 'validation is failed'
                end
              end
            end

            context 'when validate "length"' do
              let(:start_time) { '1:2:40.535' }

              context 'and when validation is passed' do
                %w[1:2:40.535 2:20.0 001:02:40.535 2:30.535 1:2:40.535 3760.1 140 999:59:59.999 1:1:1.1
                   end].each do |length|
                  context "passes cut length validation with 'length' set to #{length}" do
                    let(:length) { length }

                    it_behaves_like 'validation is passed'
                  end
                end
              end

              context 'and when validation is failed' do
                %w[:2:40.535 1000:20.0 22:64:40.535 2:30.1000 1:2:62.5 string.535 a:b:v.d].each do |length|
                  context "passes cut length validation with 'length' set to #{length}" do
                    let(:length) { length }

                    it_behaves_like 'validation is failed'
                  end
                end

                context 'fails cut length validation with the blank "length"' do
                  let(:length) { nil }

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
