# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Multi-account support' do
  let(:config_a) do
    Uploadcare::Configuration.new(
      public_key: 'account-a-public',
      secret_key: 'account-a-secret',
      auth_type: 'Uploadcare.Simple'
    )
  end

  let(:config_b) do
    Uploadcare::Configuration.new(
      public_key: 'account-b-public',
      secret_key: 'account-b-secret',
      auth_type: 'Uploadcare.Simple'
    )
  end

  let(:client_a) { Uploadcare::Client.new(config: config_a) }
  let(:client_b) { Uploadcare::Client.new(config: config_b) }

  describe 'independent client configurations' do
    it 'maintains separate configurations' do
      expect(client_a.config.public_key).to eq('account-a-public')
      expect(client_b.config.public_key).to eq('account-b-public')

      expect(client_a.config.secret_key).to eq('account-a-secret')
      expect(client_b.config.secret_key).to eq('account-b-secret')
    end

    it 'has independent API instances' do
      expect(client_a.api).not_to equal(client_b.api)
      expect(client_a.api.config.public_key).to eq('account-a-public')
      expect(client_b.api.config.public_key).to eq('account-b-public')
    end

    it 'has independent domain accessors' do
      expect(client_a.files).not_to equal(client_b.files)
      expect(client_a.groups).not_to equal(client_b.groups)
      expect(client_a.uploads).not_to equal(client_b.uploads)
      expect(client_a.project).not_to equal(client_b.project)
      expect(client_a.webhooks).not_to equal(client_b.webhooks)
      expect(client_a.addons).not_to equal(client_b.addons)
      expect(client_a.file_metadata).not_to equal(client_b.file_metadata)
      expect(client_a.conversions).not_to equal(client_b.conversions)
    end
  end

  describe 'operations with different clients' do
    let(:rest_a) { instance_double(Uploadcare::Api::Rest) }
    let(:rest_b) { instance_double(Uploadcare::Api::Rest) }
    let(:files_a) { instance_double(Uploadcare::Api::Rest::Files) }
    let(:files_b) { instance_double(Uploadcare::Api::Rest::Files) }
    let(:api_a) { instance_double(Uploadcare::Client::Api, rest: rest_a) }
    let(:api_b) { instance_double(Uploadcare::Client::Api, rest: rest_b) }

    before do
      allow(client_a).to receive(:api).and_return(api_a)
      allow(client_b).to receive(:api).and_return(api_b)
      allow(rest_a).to receive(:files).and_return(files_a)
      allow(rest_b).to receive(:files).and_return(files_b)
    end

    it 'can find files independently on different accounts' do
      file_a_attrs = { 'uuid' => 'uuid-from-account-a', 'original_filename' => 'a.jpg' }
      file_b_attrs = { 'uuid' => 'uuid-from-account-b', 'original_filename' => 'b.jpg' }

      allow(files_a).to receive(:info)
        .with(uuid: 'uuid-from-account-a', params: {}, request_options: {})
        .and_return(Uploadcare::Result.success(file_a_attrs))

      allow(files_b).to receive(:info)
        .with(uuid: 'uuid-from-account-b', params: {}, request_options: {})
        .and_return(Uploadcare::Result.success(file_b_attrs))

      file_a = Uploadcare::Resources::File.find(uuid: 'uuid-from-account-a', client: client_a)
      file_b = Uploadcare::Resources::File.find(uuid: 'uuid-from-account-b', client: client_b)

      expect(file_a.uuid).to eq('uuid-from-account-a')
      expect(file_a.client).to eq(client_a)
      expect(file_a.config.public_key).to eq('account-a-public')

      expect(file_b.uuid).to eq('uuid-from-account-b')
      expect(file_b.client).to eq(client_b)
      expect(file_b.config.public_key).to eq('account-b-public')
    end

    it 'can list files independently on different accounts' do
      list_response = {
        'results' => [],
        'next' => nil,
        'previous' => nil,
        'per_page' => 10,
        'total' => 0
      }

      allow(files_a).to receive(:list)
        .with(params: { limit: 5 }, request_options: {})
        .and_return(Uploadcare::Result.success(list_response))

      allow(files_b).to receive(:list)
        .with(params: { limit: 20 }, request_options: {})
        .and_return(Uploadcare::Result.success(list_response))

      result_a = Uploadcare::Resources::File.list(options: { limit: 5 }, client: client_a)
      result_b = Uploadcare::Resources::File.list(options: { limit: 20 }, client: client_b)

      expect(result_a).to be_a(Uploadcare::Collections::Paginated)
      expect(result_b).to be_a(Uploadcare::Collections::Paginated)
      expect(result_a.client).to eq(client_a)
      expect(result_b.client).to eq(client_b)
    end
  end

  describe 'client#with for temporary overrides' do
    it 'creates a derived client with a different key' do
      derived = client_a.with(public_key: 'temporary-key')

      expect(derived.config.public_key).to eq('temporary-key')
      expect(derived.config.secret_key).to eq('account-a-secret')
      expect(client_a.config.public_key).to eq('account-a-public')
    end

    it 'derived client operates independently' do
      derived = client_a.with(auth_type: 'Uploadcare')

      expect(derived.config.auth_type).to eq('Uploadcare')
      expect(client_a.config.auth_type).to eq('Uploadcare.Simple')
    end
  end

  describe 'resource objects retain their client context' do
    let(:rest_a) { instance_double(Uploadcare::Api::Rest) }
    let(:files_a) { instance_double(Uploadcare::Api::Rest::Files) }
    let(:api_a) { instance_double(Uploadcare::Client::Api, rest: rest_a) }

    before do
      allow(client_a).to receive(:api).and_return(api_a)
      allow(rest_a).to receive(:files).and_return(files_a)
    end

    it 'file instances use the correct client for subsequent operations' do
      file_attrs = { 'uuid' => 'file-uuid', 'original_filename' => 'test.jpg' }
      stored_attrs = file_attrs.merge('datetime_stored' => '2025-01-01T00:00:00Z')

      allow(files_a).to receive(:info)
        .with(uuid: 'file-uuid', params: {}, request_options: {})
        .and_return(Uploadcare::Result.success(file_attrs))

      allow(files_a).to receive(:store)
        .with(uuid: 'file-uuid', request_options: {})
        .and_return(Uploadcare::Result.success(stored_attrs))

      file = Uploadcare::Resources::File.find(uuid: 'file-uuid', client: client_a)
      expect(file.client).to eq(client_a)

      file.store
      expect(file.datetime_stored).to eq('2025-01-01T00:00:00Z')
      expect(file.client).to eq(client_a)
    end
  end

  describe 'global vs explicit client' do
    after do
      Uploadcare.instance_variable_set(:@client, nil)
      Uploadcare.instance_variable_set(:@configuration, nil)
    end

    it 'global client and explicit client can coexist' do
      Uploadcare.configure do |c|
        c.public_key = 'global-key'
        c.secret_key = 'global-secret'
      end

      global_client = Uploadcare.client
      expect(global_client.config.public_key).to eq('global-key')

      expect(client_a.config.public_key).to eq('account-a-public')
      expect(client_b.config.public_key).to eq('account-b-public')
    end
  end
end
