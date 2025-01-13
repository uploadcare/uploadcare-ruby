# frozen_string_literal: true

RSpec.describe Uploadcare::WebhookClient do
  subject(:webhook_client) { described_class.new }

  describe '#list_webhooks' do
    let(:response_body) do
      [
        {
          'id' => 1,
          'project' => 13,
          'created' => '2016-04-27T11:49:54.948615Z',
          'updated' => '2016-04-27T12:04:57.819933Z',
          'event' => 'file.infected',
          'target_url' => 'http://example.com/hooks/receiver',
          'is_active' => true,
          'signing_secret' => '7kMVZivndx0ErgvhRKAr',
          'version' => '0.7'
        }
      ]
    end

    before do
      stub_request(:get, 'https://api.uploadcare.com/webhooks/')
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns a list of webhooks' do
      response = webhook_client.list_webhooks
      expect(response).to eq(response_body)
    end
  end

  describe '#create_webhook' do
    let(:target_url) { 'https://example.com/hooks' }
    let(:event) { 'file.uploaded' }
    let(:is_active) { true }
    let(:signing_secret) { 'secret' }
    let(:version) { '0.7' }
    let(:payload) do
      {
        target_url: target_url,
        event: event,
        is_active: is_active,
        signing_secret: signing_secret,
        version: version
      }
    end

    let(:response_body) do
      {
        'id' => 1,
        'project' => 13,
        'created' => '2016-04-27T11:49:54.948615Z',
        'updated' => '2016-04-27T12:04:57.819933Z',
        'event' => event,
        'target_url' => target_url,
        'is_active' => is_active,
        'signing_secret' => signing_secret,
        'version' => version
      }
    end

    before do
      stub_request(:post, 'https://api.uploadcare.com/webhooks/')
        .with(body: payload)
        .to_return(
          status: 201,
          body: response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'creates a new webhook' do
      response = webhook_client.create_webhook(
        target_url,
        event,
        is_active,
        signing_secret,
        version
      )
      expect(response).to eq(response_body)
    end
  end
  describe '#update_webhook' do
    let(:webhook_id) { 1 }
    let(:payload) do
      {
        target_url: 'https://example.com/hooks/updated',
        event: 'file.uploaded',
        is_active: true,
        signing_secret: 'updated-secret'
      }
    end

    let(:response_body) do
      {
        'id' => 1,
        'project' => 13,
        'created' => '2016-04-27T11:49:54.948615Z',
        'updated' => '2016-04-27T12:04:57.819933Z',
        'event' => 'file.uploaded',
        'target_url' => 'https://example.com/hooks/updated',
        'is_active' => true,
        'signing_secret' => 'updated-secret',
        'version' => '0.7'
      }
    end

    before do
      stub_request(:put, "https://api.uploadcare.com/webhooks/#{webhook_id}/")
        .with(body: payload)
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'updates the webhook and returns the updated attributes' do
      response = webhook_client.update_webhook(
        webhook_id,
        'https://example.com/hooks/updated',
        'file.uploaded',
        is_active: true,
        signing_secret: 'updated-secret'
      )
      expect(response).to eq(response_body)
    end
  end

  describe '#delete_webhook' do
    let(:target_url) { 'http://example.com' }

    before do
      stub_request(:delete, 'https://api.uploadcare.com/webhooks/unsubscribe/')
        .with(body: { target_url: target_url })
        .to_return(status: 204)
    end

    it 'deletes the webhook successfully' do
      VCR.use_cassette('rest_webhook_destroy') do
        expect { subject.delete_webhook(target_url) }.not_to raise_error
      end
    end
  end
end
