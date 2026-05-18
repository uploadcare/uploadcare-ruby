# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api::Rest::Webhooks do
  subject(:webhooks) { described_class.new(rest: rest) }

  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end

  let(:rest) { Uploadcare::Api::Rest.new(config: config) }

  describe '#initialize' do
    it 'stores the rest client' do
      expect(webhooks.rest).to eq(rest)
    end
  end

  describe '#list' do
    before do
      stub_request(:get, 'https://api.uploadcare.com/webhooks/')
        .to_return(
          status: 200,
          body: [
            {
              id: 1,
              target_url: 'https://example.com/webhook',
              event: 'file.uploaded',
              is_active: true,
              project: 12_345
            }
          ].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns a list of webhooks' do
      result = webhooks.list

      expect(result).to be_success
      expect(result.value!).to be_an(Array)
      expect(result.value!.first['target_url']).to eq('https://example.com/webhook')
    end
  end

  describe '#create' do
    before do
      stub_request(:post, 'https://api.uploadcare.com/webhooks/')
        .to_return(
          status: 200,
          body: {
            id: 123,
            target_url: 'https://example.com/hook',
            event: 'file.uploaded',
            is_active: true
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'creates a webhook with the given target URL' do
      result = webhooks.create(options: { target_url: 'https://example.com/hook' })

      expect(result).to be_success
      expect(result.value!['id']).to eq(123)
      expect(result.value!['target_url']).to eq('https://example.com/hook')
    end

    it 'defaults event to file.uploaded' do
      stub_request(:post, 'https://api.uploadcare.com/webhooks/')
        .with(body: hash_including('event' => 'file.uploaded'))
        .to_return(
          status: 200,
          body: { id: 123, event: 'file.uploaded' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.create(options: { target_url: 'https://example.com/hook' })

      expect(result).to be_success
    end

    it 'defaults is_active to true' do
      stub_request(:post, 'https://api.uploadcare.com/webhooks/')
        .with(body: hash_including('is_active' => true))
        .to_return(
          status: 200,
          body: { id: 123, is_active: true }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.create(options: { target_url: 'https://example.com/hook' })

      expect(result).to be_success
    end

    it 'accepts optional signing_secret' do
      stub_request(:post, 'https://api.uploadcare.com/webhooks/')
        .with(body: hash_including('signing_secret' => 'my-secret'))
        .to_return(
          status: 200,
          body: { id: 123, signing_secret: 'my-secret' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.create(options: { target_url: 'https://example.com/hook', signing_secret: 'my-secret' })

      expect(result).to be_success
    end

    it 'accepts optional version' do
      stub_request(:post, 'https://api.uploadcare.com/webhooks/')
        .with(body: hash_including('version' => '0.7'))
        .to_return(
          status: 200,
          body: { id: 123, version: '0.7' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.create(options: { target_url: 'https://example.com/hook', version: '0.7' })

      expect(result).to be_success
    end

    it 'allows setting is_active to false' do
      stub_request(:post, 'https://api.uploadcare.com/webhooks/')
        .with(body: hash_including('is_active' => false))
        .to_return(
          status: 200,
          body: { id: 123, is_active: false }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.create(options: { target_url: 'https://example.com/hook', is_active: false })

      expect(result).to be_success
    end
  end

  describe '#update' do
    before do
      stub_request(:put, 'https://api.uploadcare.com/webhooks/123/')
        .to_return(
          status: 200,
          body: {
            id: 123,
            target_url: 'https://example.com/updated-hook',
            event: 'file.uploaded',
            is_active: true
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'updates a webhook by ID' do
      result = webhooks.update(id: 123, options: { target_url: 'https://example.com/updated-hook' })

      expect(result).to be_success
      expect(result.value!['target_url']).to eq('https://example.com/updated-hook')
    end

    it 'can update is_active' do
      stub_request(:put, 'https://api.uploadcare.com/webhooks/123/')
        .with(body: hash_including('is_active' => false))
        .to_return(
          status: 200,
          body: { id: 123, is_active: false }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = webhooks.update(id: 123, options: { is_active: false })

      expect(result).to be_success
      expect(result.value!['is_active']).to be false
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, 'https://api.uploadcare.com/webhooks/unsubscribe/')
        .to_return(
          status: 200,
          body: ''.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'deletes a webhook by target URL' do
      result = webhooks.delete(target_url: 'https://example.com/hook')

      expect(result).to be_a(Uploadcare::Result)
      expect(result).to be_success
    end

    it 'sends the target_url in the request body' do
      stub = stub_request(:delete, 'https://api.uploadcare.com/webhooks/unsubscribe/')
             .with(body: hash_including('target_url' => 'https://example.com/hook'))
             .to_return(
               status: 200,
               body: ''.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      webhooks.delete(target_url: 'https://example.com/hook')

      expect(stub).to have_been_requested
    end
  end
end
