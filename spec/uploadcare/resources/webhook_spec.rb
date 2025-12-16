# frozen_string_literal: true

RSpec.describe Uploadcare::Webhook do
  describe '.list' do
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
      allow_any_instance_of(Uploadcare::WebhookClient).to receive(:list_webhooks).and_return(response_body)
    end

    it 'returns a list of webhooks as Webhook objects' do
      webhooks = described_class.list
      expect(webhooks).to all(be_a(described_class))
      expect(webhooks.first.id).to eq(1)
      expect(webhooks.first.event).to eq('file.infected')
      expect(webhooks.first.target_url).to eq('http://example.com/hooks/receiver')
    end
  end
  describe '.create' do
    let(:target_url) { 'https://example.com/hooks' }
    let(:event) { 'file.uploaded' }
    let(:is_active) { true }
    let(:signing_secret) { 'secret' }
    let(:version) { '0.7' }
    let(:response_body) do
      {
        'id' => 1,
        'project' => 13,
        'created' => '2016-04-27T11:49:54.948615Z',
        'updated' => '2016-04-27T12:04:57.819933Z',
        'event' => 'file.uploaded',
        'target_url' => 'https://example.com/hooks',
        'is_active' => true,
        'signing_secret' => 'secret',
        'version' => '0.7'
      }
    end

    before do
      allow_any_instance_of(Uploadcare::WebhookClient).to receive(:create_webhook)
        .with(hash_including(target_url: target_url, event: event, is_active: is_active, signing_secret: signing_secret))
        .and_return(response_body)
    end

    it 'creates a new webhook with hash arguments (v4.4.3 compatible)' do
      webhook = described_class.create(target_url: target_url, event: event, is_active: is_active, signing_secret: signing_secret)
      expect(webhook).to be_a(described_class)
      expect(webhook.id).to eq(1)
      expect(webhook.event).to eq('file.uploaded')
      expect(webhook.target_url).to eq('https://example.com/hooks')
    end

    it 'creates webhook with minimal arguments like v4.4.3' do
      allow_any_instance_of(Uploadcare::WebhookClient).to receive(:create_webhook)
        .with(hash_including(target_url: target_url))
        .and_return(response_body)

      webhook = described_class.create(target_url: target_url)
      expect(webhook).to be_a(described_class)
      expect(webhook.target_url).to eq('https://example.com/hooks')
    end

    it 'uses default values for event and is_active like v4.4.3' do
      expect_any_instance_of(Uploadcare::WebhookClient).to receive(:create_webhook) do |_, options|
        expect(options[:event]).to be_nil # Will default to 'file.uploaded' in client
        expect(options[:is_active]).to be_nil # Will default to true in client
        response_body
      end

      described_class.create(target_url: target_url)
    end
  end
  describe '.update' do
    let(:webhook_id) { 1 }
    let(:target_url) { 'https://example.com/hooks/updated' }
    let(:event) { 'file.uploaded' }
    let(:is_active) { true }
    let(:signing_secret) { 'updated-secret' }
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
      allow_any_instance_of(Uploadcare::WebhookClient).to receive(:update_webhook)
        .with(webhook_id, hash_including(target_url: target_url, event: event, is_active: is_active, signing_secret: signing_secret))
        .and_return(response_body)
    end

    it 'returns the updated webhook as an object (v4.4.3 compatible)' do
      webhook = described_class.update(webhook_id, target_url: target_url, event: event, is_active: is_active, signing_secret: signing_secret)
      expect(webhook).to be_a(described_class)
      expect(webhook.id).to eq(1)
      expect(webhook.target_url).to eq(target_url)
      expect(webhook.event).to eq(event)
      expect(webhook.is_active).to eq(true)
      expect(webhook.signing_secret).to eq(signing_secret)
    end

    it 'updates webhook with partial options like v4.4.3' do
      allow_any_instance_of(Uploadcare::WebhookClient).to receive(:update_webhook)
        .with(webhook_id, hash_including(target_url: target_url))
        .and_return(response_body)

      webhook = described_class.update(webhook_id, target_url: target_url)
      expect(webhook).to be_a(described_class)
      expect(webhook.target_url).to eq(target_url)
    end
  end
  describe '.delete' do
    let(:target_url) { 'https://example.com/hooks' }

    before do
      allow_any_instance_of(Uploadcare::WebhookClient).to receive(:delete_webhook)
        .with(target_url).and_return(nil)
    end

    it 'deletes the webhook successfully (v4.4.3 compatible)' do
      expect { described_class.delete(target_url) }.not_to raise_error
    end

    it 'passes target_url to client for deletion' do
      expect_any_instance_of(Uploadcare::WebhookClient).to receive(:delete_webhook)
        .with(target_url)

      described_class.delete(target_url)
    end

    it 'returns nil on successful deletion like v4.4.3' do
      result = described_class.delete(target_url)
      expect(result).to be_nil
    end

    it 'accepts string URLs like v4.4.3' do
      url = 'https://example.com/webhook'
      expect_any_instance_of(Uploadcare::WebhookClient).to receive(:delete_webhook)
        .with(url).and_return(nil)

      expect { described_class.delete(url) }.not_to raise_error
    end
  end
end
