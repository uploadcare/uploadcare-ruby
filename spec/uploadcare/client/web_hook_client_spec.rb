require 'spec_helper'

module Uploadcare
  RSpec.describe WebhookClient do
    subject { WebhookClient.new }

    describe 'list' do
      it 'prevents you from accessing this feature on unpaid accounts' do
        VCR.use_cassette('rest_webhook_list_unpaid') do
          response = subject.list
          expect(response.failure.body[:detail]).to eq("You can't use webhooks")
        end
      end
    end
  end
end
