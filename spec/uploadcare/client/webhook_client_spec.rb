# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe WebhookClient do
      subject { WebhookClient.new }

      describe 'create' do
        it 'creates a webhook' do
          VCR.use_cassette('rest_webhook_create') do
            target_url = 'http://ohmyz.sh'
            response = subject.create(target_url)
            response_value = response.value!
            expect(response_value[:target_url]).to eq(target_url)
            expect(response_value[:id]).not_to be nil
          end
        end
      end

      describe 'list' do
        it 'lists an array of webhooks' do
          VCR.use_cassette('rest_webhook_list') do
            response = subject.list
            response_value = response.value!
            expect(response_value).to be_a_kind_of(Array)
          end
        end
      end

      describe 'delete' do
        it 'destroys a webhook' do
          VCR.use_cassette('rest_webhook_destroy') do
            response = subject.delete('http://example.com')
            response_value = response.value!
            expect(response_value).to be_nil
            expect(response.success?).to be true
          end
        end
      end

      describe 'update' do
        it 'updates a webhook' do
          VCR.use_cassette('rest_webhook_update') do
            sub_id = 616_294
            target_url = 'https://github.com'
            is_active = false
            response = subject.update(sub_id, target_url: target_url, is_active: is_active)
            response_value = response.value!
            expect(response_value[:id]).to eq(sub_id)
            expect(response_value[:target_url]).to eq(target_url)
            expect(response_value[:is_active]).to eq(is_active)
          end
        end
      end
    end
  end
end
