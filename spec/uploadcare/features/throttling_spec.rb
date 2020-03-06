# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe 'throttling' do
    let!(:file) { ::File.open('spec/fixtures/kitten.jpeg') }
    Kernel.class_eval do
      # prevent waiting time
      def sleep(_time); end
    end

    context 'REST API' do
      context 'cassette with 3 throttled responses and one proper response' do
        it 'makes multiple attempts on throttled requests' do
          VCR.use_cassette('throttling') do
            expect { Entity::File.info('8f64f313-e6b1-4731-96c0-6751f1e7a50a') }.not_to raise_error
            # make sure this cassette actually had 3 throttled responses
            assert_requested(:get, 'https://api.uploadcare.com/files/8f64f313-e6b1-4731-96c0-6751f1e7a50a/', times: 4)
          end
        end
      end
    end

    context 'Upload API' do
      context 'cassette with a throttled response' do
        it 'makes multiple attempts on throttled requests' do
          VCR.use_cassette('upload_throttling') do
            expect { Entity::Uploader.upload(file) }.not_to raise_error
            # make sure this cassette actually had a throttled response
            assert_requested(:post, 'https://upload.uploadcare.com/base/', times: 2)
          end
        end
      end
    end
  end
end
