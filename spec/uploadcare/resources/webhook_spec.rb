# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Resources::Webhook do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:rest) { instance_double(Uploadcare::Api::Rest) }
  let(:rest_webhooks) { instance_double(Uploadcare::Api::Rest::Webhooks) }
  let(:api) { instance_double(Uploadcare::Client::Api, rest: rest) }

  let(:webhook_attrs) do
    {
      'id' => 123,
      'project' => 456,
      'created' => '2025-01-01T00:00:00Z',
      'updated' => '2025-01-01T00:00:00Z',
      'event' => 'file.uploaded',
      'target_url' => 'https://example.com/webhook',
      'is_active' => true,
      'signing_secret' => 'secret123',
      'version' => '0.7'
    }
  end

  before do
    allow(client).to receive(:api).and_return(api)
    allow(rest).to receive(:webhooks).and_return(rest_webhooks)
  end

  describe '.list' do
    it 'returns an array of Webhook resources' do
      allow(rest_webhooks).to receive(:list)
        .with(request_options: {})
        .and_return(Uploadcare::Result.success([webhook_attrs]))

      result = described_class.list(client: client)
      expect(result).to be_an(Array)
      expect(result.length).to eq(1)
      expect(result.first).to be_a(described_class)
      expect(result.first.id).to eq(123)
      expect(result.first.target_url).to eq('https://example.com/webhook')
      expect(result.first.event).to eq('file.uploaded')
    end

    it 'returns empty array when no webhooks exist' do
      allow(rest_webhooks).to receive(:list)
        .with(request_options: {})
        .and_return(Uploadcare::Result.success([]))

      result = described_class.list(client: client)
      expect(result).to eq([])
    end
  end

  describe '.create' do
    it 'creates a webhook with default event and is_active' do
      allow(rest_webhooks).to receive(:create)
        .with(
          options: { target_url: 'https://example.com/hook', event: 'file.uploaded', is_active: true },
          request_options: {}
        )
        .and_return(Uploadcare::Result.success(webhook_attrs))

      webhook = described_class.create(target_url: 'https://example.com/hook', client: client)
      expect(webhook).to be_a(described_class)
      expect(webhook.target_url).to eq('https://example.com/webhook')
    end

    it 'creates a webhook with custom event and is_active' do
      allow(rest_webhooks).to receive(:create)
        .with(
          options: { target_url: 'https://example.com/hook', event: 'file.stored', is_active: false },
          request_options: {}
        )
        .and_return(Uploadcare::Result.success(webhook_attrs.merge('event' => 'file.stored', 'is_active' => false)))

      webhook = described_class.create(
        target_url: 'https://example.com/hook',
        event: 'file.stored',
        is_active: false,
        client: client
      )
      expect(webhook).to be_a(described_class)
    end

    it 'includes signing_secret when provided' do
      allow(rest_webhooks).to receive(:create)
        .with(
          options: {
            target_url: 'https://example.com/hook',
            event: 'file.uploaded',
            is_active: true,
            signing_secret: 'my-secret'
          },
          request_options: {}
        )
        .and_return(Uploadcare::Result.success(webhook_attrs))

      described_class.create(
        target_url: 'https://example.com/hook',
        signing_secret: 'my-secret',
        client: client
      )
    end

    it 'includes version when provided' do
      allow(rest_webhooks).to receive(:create)
        .with(
          options: {
            target_url: 'https://example.com/hook',
            event: 'file.uploaded',
            is_active: true,
            version: '0.7'
          },
          request_options: {}
        )
        .and_return(Uploadcare::Result.success(webhook_attrs))

      described_class.create(
        target_url: 'https://example.com/hook',
        version: '0.7',
        client: client
      )
    end
  end

  describe '.update' do
    it 'updates a webhook by id' do
      updated_attrs = webhook_attrs.merge('target_url' => 'https://new-url.com/hook')

      allow(rest_webhooks).to receive(:update)
        .with(
          id: 123,
          options: { target_url: 'https://new-url.com/hook' },
          request_options: {}
        )
        .and_return(Uploadcare::Result.success(updated_attrs))

      webhook = described_class.update(id: 123, target_url: 'https://new-url.com/hook', client: client)
      expect(webhook).to be_a(described_class)
      expect(webhook.target_url).to eq('https://new-url.com/hook')
    end

    it 'can update is_active' do
      allow(rest_webhooks).to receive(:update)
        .with(
          id: 123,
          options: { is_active: false },
          request_options: {}
        )
        .and_return(Uploadcare::Result.success(webhook_attrs.merge('is_active' => false)))

      webhook = described_class.update(id: 123, is_active: false, client: client)
      expect(webhook.is_active).to be false
    end
  end

  describe '.delete' do
    it 'deletes a webhook by target_url' do
      allow(rest_webhooks).to receive(:delete)
        .with(target_url: 'https://example.com/webhook', request_options: {})
        .and_return(Uploadcare::Result.success(nil))

      expect {
        described_class.delete(target_url: 'https://example.com/webhook', client: client)
      }.not_to raise_error
    end

    it 'is aliased as unsubscribe' do
      expect(described_class).to respond_to(:unsubscribe)
    end
  end

  describe 'attributes' do
    it 'exposes all webhook attributes' do
      webhook = described_class.new(webhook_attrs, client)
      expect(webhook.id).to eq(123)
      expect(webhook.project).to eq(456)
      expect(webhook.created).to eq('2025-01-01T00:00:00Z')
      expect(webhook.updated).to eq('2025-01-01T00:00:00Z')
      expect(webhook.event).to eq('file.uploaded')
      expect(webhook.target_url).to eq('https://example.com/webhook')
      expect(webhook.is_active).to be true
      expect(webhook.signing_secret).to eq('secret123')
      expect(webhook.version).to eq('0.7')
    end
  end
end
