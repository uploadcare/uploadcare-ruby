# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe Webhook do
    subject { Webhook }
    it 'responds to expected methods' do
      %i[list delete update].each do |method|
        expect(subject).to respond_to(method)
      end
    end

    describe 'create' do
      it 'represents a webhook' do
        VCR.use_cassette('rest_webhook_create') do
          target_url = 'http://ohmyz.sh'
          webhook = subject.create(target_url)
          %i[created event id is_active project target_url updated].each do |field|
            expect(webhook[field]).not_to be_nil
          end
        end
      end
    end

    describe 'list' do
      it 'returns list of webhooks' do
        VCR.use_cassette('rest_webhook_list') do
          webhooks = subject.list
          expect(webhooks).to be_kind_of(ApiStruct::Collection)
        end
      end
    end
  end
end
