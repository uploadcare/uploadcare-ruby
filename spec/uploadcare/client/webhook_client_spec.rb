require 'spec_helper'

module Uploadcare
  RSpec.describe WebhookClient do
    subject { WebhookClient.new }

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
          pending('There is no successful example of response in docs')
          response = subject.delete('example.com')
          response_value = response.value!
          expect(response.success[:detail]).to eq("Something specific about deletion")
        end
      end
    end

    describe 'update' do
      it 'updates a webhook' do
        VCR.use_cassette('rest_webhook_update') do
          response = subject.update(1)
          response_value = response.value!
          expect(response_value[:id]).to eq(1)
        end
      end
    end
  end
end
