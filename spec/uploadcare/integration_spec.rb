# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Integration: end-to-end workflows' do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple',
      rest_api_root: 'https://api.uploadcare.com',
      upload_api_root: 'https://upload.uploadcare.com'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }
  let(:file_data) do
    {
      'uuid' => file_uuid,
      'original_filename' => 'test.jpg',
      'size' => 1024,
      'mime_type' => 'image/jpeg',
      'is_ready' => true,
      'is_image' => true,
      'datetime_uploaded' => '2025-01-01T00:00:00Z',
      'url' => "https://ucarecdn.com/#{file_uuid}/"
    }
  end

  describe 'file lifecycle: find → store → delete' do
    before do
      stub_request(:get, "https://api.uploadcare.com/files/#{file_uuid}/")
        .to_return(
          status: 200,
          body: file_data.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:put, "https://api.uploadcare.com/files/#{file_uuid}/storage/")
        .to_return(
          status: 200,
          body: file_data.merge('datetime_stored' => '2025-01-02T00:00:00Z').to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:delete, "https://api.uploadcare.com/files/#{file_uuid}/storage/")
        .to_return(
          status: 200,
          body: file_data.merge('datetime_removed' => '2025-01-03T00:00:00Z').to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'performs the full lifecycle' do
      file = client.files.find(uuid: file_uuid)
      expect(file).to be_a(Uploadcare::Resources::File)
      expect(file.uuid).to eq(file_uuid)
      expect(file.original_filename).to eq('test.jpg')

      file.store
      expect(file.datetime_stored).to eq('2025-01-02T00:00:00Z')

      file.delete
      expect(file.datetime_removed).to eq('2025-01-03T00:00:00Z')
    end
  end

  describe 'file listing with pagination' do
    before do
      stub_request(:get, 'https://api.uploadcare.com/files/')
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: {
            'results' => [file_data],
            'next' => 'https://api.uploadcare.com/files/?limit=1&offset=1',
            'previous' => nil,
            'per_page' => 1,
            'total' => 2
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, 'https://api.uploadcare.com/files/')
        .with(query: { 'limit' => '1', 'offset' => '1' })
        .to_return(
          status: 200,
          body: {
            'results' => [file_data.merge('uuid' => 'second-uuid')],
            'next' => nil,
            'previous' => 'https://api.uploadcare.com/files/?limit=1',
            'per_page' => 1,
            'total' => 2
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'lists files and navigates pages' do
      page1 = client.files.list(limit: 1)
      expect(page1).to be_a(Uploadcare::Collections::Paginated)
      expect(page1.total).to eq(2)
      expect(page1.count).to eq(1)
      expect(page1.first.uuid).to eq(file_uuid)

      page2 = page1.next_page
      expect(page2).to be_a(Uploadcare::Collections::Paginated)
      expect(page2.first.uuid).to eq('second-uuid')
      expect(page2.next_page).to be_nil
    end
  end

  describe 'batch file operations' do
    let(:uuids) { %w[uuid-1 uuid-2] }

    before do
      stub_request(:put, 'https://api.uploadcare.com/files/storage/')
        .to_return(
          status: 200,
          body: {
            'status' => 'ok',
            'result' => uuids.map { |u| { 'uuid' => u } },
            'problems' => {}
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'batch stores files' do
      result = client.files.batch_store(uuids: uuids)
      expect(result).to be_a(Uploadcare::Collections::BatchResult)
      expect(result.result.length).to eq(2)
      expect(result.problems).to be_empty
    end
  end

  describe 'group lifecycle: create → find → delete' do
    let(:group_id) { "#{file_uuid}~2" }
    let(:group_data) do
      {
        'id' => group_id,
        'files_count' => 2,
        'datetime_created' => '2025-01-01T00:00:00Z',
        'files' => [file_data, file_data.merge('uuid' => 'uuid-2')]
      }
    end

    before do
      stub_request(:post, 'https://upload.uploadcare.com/group/')
        .to_return(
          status: 200,
          body: group_data.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://api.uploadcare.com/groups/#{URI.encode_www_form_component(group_id)}/")
        .to_return(
          status: 200,
          body: group_data.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:delete, "https://api.uploadcare.com/groups/#{URI.encode_www_form_component(group_id)}/")
        .to_return(status: 204, body: '', headers: {})
    end

    it 'performs the full group lifecycle' do
      group = client.groups.create([file_uuid, 'uuid-2'])
      expect(group).to be_a(Uploadcare::Resources::Group)
      expect(group.id).to eq(group_id)
      expect(group.files_count).to eq(2)

      found = client.groups.find(group_id: group_id)
      expect(found.id).to eq(group_id)

      expect(found.file_cdn_urls.length).to eq(2)
    end
  end

  describe 'webhook lifecycle: create → list → update → delete' do
    let(:webhook_data) do
      {
        'id' => 123,
        'target_url' => 'https://example.com/webhook',
        'event' => 'file.uploaded',
        'is_active' => true,
        'project' => 42
      }
    end

    before do
      stub_request(:post, 'https://api.uploadcare.com/webhooks/')
        .to_return(
          status: 200,
          body: webhook_data.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, 'https://api.uploadcare.com/webhooks/')
        .to_return(
          status: 200,
          body: [webhook_data].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:put, 'https://api.uploadcare.com/webhooks/123/')
        .to_return(
          status: 200,
          body: webhook_data.merge('is_active' => false).to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:delete, 'https://api.uploadcare.com/webhooks/unsubscribe/')
        .to_return(status: 204, body: '', headers: {})
    end

    it 'performs the full webhook lifecycle' do
      webhook = client.webhooks.create(target_url: 'https://example.com/webhook')
      expect(webhook).to be_a(Uploadcare::Resources::Webhook)
      expect(webhook.id).to eq(123)

      webhooks = client.webhooks.list
      expect(webhooks.length).to eq(1)

      updated = client.webhooks.update(id: 123, is_active: false)
      expect(updated.is_active).to be(false)

      client.webhooks.delete(target_url: 'https://example.com/webhook')
    end
  end

  describe 'project info' do
    before do
      stub_request(:get, 'https://api.uploadcare.com/project/')
        .to_return(
          status: 200,
          body: { 'name' => 'Test Project', 'pub_key' => 'demopublickey', 'autostore_enabled' => true }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'retrieves project info' do
      project = client.project.current
      expect(project).to be_a(Uploadcare::Resources::Project)
      expect(project.name).to eq('Test Project')
      expect(project.pub_key).to eq('demopublickey')
    end
  end

  describe 'file metadata lifecycle' do
    before do
      stub_request(:get, "https://api.uploadcare.com/files/#{file_uuid}/metadata/")
        .to_return(
          status: 200,
          body: { 'key1' => 'value1' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:put, "https://api.uploadcare.com/files/#{file_uuid}/metadata/key2/")
        .to_return(
          status: 200,
          body: '"value2"',
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://api.uploadcare.com/files/#{file_uuid}/metadata/key1/")
        .to_return(
          status: 200,
          body: '"value1"',
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:delete, "https://api.uploadcare.com/files/#{file_uuid}/metadata/key1/")
        .to_return(status: 204, body: '', headers: {})
    end

    it 'performs metadata operations' do
      metadata = client.file_metadata.index(uuid: file_uuid)
      expect(metadata).to eq({ 'key1' => 'value1' })

      client.file_metadata.update(uuid: file_uuid, key: 'key2', value: 'value2')

      value = client.file_metadata.show(uuid: file_uuid, key: 'key1')
      expect(value).to eq('value1')

      client.file_metadata.delete(uuid: file_uuid, key: 'key1')
    end
  end

  describe 'multi-account support' do
    let(:config_a) { Uploadcare::Configuration.new(public_key: 'key_a', secret_key: 'secret_a', auth_type: 'Uploadcare.Simple') }
    let(:config_b) { Uploadcare::Configuration.new(public_key: 'key_b', secret_key: 'secret_b', auth_type: 'Uploadcare.Simple') }
    let(:client_a) { Uploadcare::Client.new(config: config_a) }
    let(:client_b) { Uploadcare::Client.new(config: config_b) }

    it 'maintains independent configurations' do
      expect(client_a.config.public_key).to eq('key_a')
      expect(client_b.config.public_key).to eq('key_b')
      expect(client_a.config).not_to equal(client_b.config)
    end

    it 'creates independent API clients' do
      expect(client_a.api.rest).not_to equal(client_b.api.rest)
      expect(client_a.api.upload).not_to equal(client_b.api.upload)
    end

    it 'supports config.with for overrides' do
      client_c = client_a.with(public_key: 'key_c')
      expect(client_c.config.public_key).to eq('key_c')
      expect(client_c.config.secret_key).to eq('secret_a')
      expect(client_a.config.public_key).to eq('key_a')
    end
  end

  describe 'add-on execution' do
    before do
      stub_request(:post, 'https://api.uploadcare.com/addons/aws_rekognition_detect_labels/execute/')
        .to_return(
          status: 200,
          body: { 'request_id' => 'req-123' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, 'https://api.uploadcare.com/addons/aws_rekognition_detect_labels/execute/status/')
        .with(query: { 'request_id' => 'req-123' })
        .to_return(
          status: 200,
          body: { 'status' => 'done', 'result' => { 'labels' => ['cat'] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'executes addon and checks status' do
      execution = client.addons.aws_rekognition_detect_labels(uuid: file_uuid)
      expect(execution).to be_a(Uploadcare::Resources::AddonExecution)
      expect(execution.request_id).to eq('req-123')

      status = client.addons.aws_rekognition_detect_labels_status(request_id: 'req-123')
      expect(status.status).to eq('done')
    end
  end

  describe 'conversion workflow' do
    before do
      stub_request(:post, 'https://api.uploadcare.com/convert/document/')
        .to_return(
          status: 200,
          body: { 'result' => [{ 'uuid' => 'converted-uuid', 'token' => 123 }], 'problems' => {} }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, 'https://api.uploadcare.com/convert/document/status/123/')
        .to_return(
          status: 200,
          body: { 'status' => 'finished', 'result' => { 'uuid' => 'converted-uuid' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'converts document and checks status' do
      result = client.conversions.documents.convert(uuid: file_uuid, format: 'pdf')
      expect(result).to be_a(Hash)
      expect(result['result'].first['uuid']).to eq('converted-uuid')

      status = client.conversions.documents.status(token: 123)
      expect(status.status).to eq('finished')
    end
  end

  describe 'global convenience accessors' do
    it 'provides files through Uploadcare.files' do
      expect(Uploadcare.files).to be_a(Uploadcare::Client::FilesAccessor)
    end

    it 'provides groups through Uploadcare.groups' do
      expect(Uploadcare.groups).to be_a(Uploadcare::Client::GroupsAccessor)
    end

    it 'provides uploads through Uploadcare.uploads' do
      expect(Uploadcare.uploads).to be_a(Uploadcare::Operations::UploadRouter)
    end

    it 'provides project through Uploadcare.project' do
      expect(Uploadcare.project).to be_a(Uploadcare::Client::ProjectAccessor)
    end
  end
end
