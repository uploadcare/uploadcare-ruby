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
    let(:options) do
      {
        target_url: target_url,
        event: event,
        is_active: is_active,
        signing_secret: signing_secret
      }
    end
    let(:expected_payload) do
      {
        target_url: target_url,
        event: event,
        is_active: is_active,
        signing_secret: signing_secret
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
        'version' => '0.7'
      }
    end

    before do
      stub_request(:post, 'https://api.uploadcare.com/webhooks/')
        .with(body: expected_payload)
        .to_return(
          status: 201,
          body: response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'creates a new webhook with options hash (v4.4.3 compatible)' do
      response = webhook_client.create_webhook(options)
      expect(response).to eq(response_body)
    end

    it 'uses default values when options are missing' do
      stub_request(:post, 'https://api.uploadcare.com/webhooks/')
        .with(body: { target_url: target_url, event: 'file.uploaded', is_active: true })
        .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

      response = webhook_client.create_webhook(target_url: target_url)
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

    it 'updates the webhook with options hash (v4.4.3 compatible)' do
      response = webhook_client.update_webhook(webhook_id, payload)
      expect(response).to eq(response_body)
    end

    it 'accepts partial updates like v4.4.3' do
      partial_payload = { target_url: 'https://example.com/hooks/new' }
      stub_request(:put, "https://api.uploadcare.com/webhooks/#{webhook_id}/")
        .with(body: partial_payload)
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

      response = webhook_client.update_webhook(webhook_id, partial_payload)
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
      expect { subject.delete_webhook(target_url) }.not_to raise_error
    end

    it 'sends target_url in request body like v4.4.3' do
      result = subject.delete_webhook(target_url)
      expect([nil, '']).to include(result) # API may return empty string or nil
    end

    it 'handles various URL formats' do
      urls = ['http://example.com', 'https://api.example.com/webhook']
      urls.each do |url|
        stub_request(:delete, 'https://api.uploadcare.com/webhooks/unsubscribe/')
          .with(body: { target_url: url })
          .to_return(status: 204)

        expect { subject.delete_webhook(url) }.not_to raise_error
      end
    end
  end
end
