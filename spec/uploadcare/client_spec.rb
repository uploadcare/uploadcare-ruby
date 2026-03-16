# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Client do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { described_class.new(config: config) }

  describe '#initialize' do
    it 'accepts a config object' do
      expect(client.config).to eq(config)
    end

    it 'defaults to Uploadcare.configuration when no config given' do
      default_client = described_class.new
      expect(default_client.config).to be_a(Uploadcare::Configuration)
    end

    it 'applies overrides to the config' do
      custom_client = described_class.new(config: config, public_key: 'overridden')
      expect(custom_client.config.public_key).to eq('overridden')
      expect(custom_client.config.secret_key).to eq('demosecretkey')
    end

    it 'does not mutate the original config' do
      described_class.new(config: config, public_key: 'overridden')
      expect(config.public_key).to eq('demopublickey')
    end
  end

  describe '#with' do
    it 'creates a new client with overridden config' do
      new_client = client.with(public_key: 'new-key')
      expect(new_client).to be_a(described_class)
      expect(new_client.config.public_key).to eq('new-key')
      expect(new_client.config.secret_key).to eq('demosecretkey')
    end

    it 'does not modify the original client' do
      client.with(public_key: 'changed')
      expect(client.config.public_key).to eq('demopublickey')
    end
  end

  describe '#api' do
    it 'returns an Api instance' do
      expect(client.api).to be_a(Uploadcare::Client::Api)
    end

    it 'memoizes the api instance' do
      expect(client.api).to equal(client.api)
    end
  end

  describe Uploadcare::Client::Api do
    let(:api) { Uploadcare::Client::Api.new(config: config) }

    describe '#rest' do
      it 'returns a Rest API client' do
        expect(api.rest).to be_a(Uploadcare::Api::Rest)
      end

      it 'memoizes the rest client' do
        expect(api.rest).to equal(api.rest)
      end
    end

    describe '#upload' do
      it 'returns an Upload API client' do
        expect(api.upload).to be_a(Uploadcare::Api::Upload)
      end

      it 'memoizes the upload client' do
        expect(api.upload).to equal(api.upload)
      end
    end
  end

  describe '#files' do
    it 'returns a FilesAccessor' do
      expect(client.files).to be_a(Uploadcare::Client::FilesAccessor)
    end

    it 'memoizes the accessor' do
      expect(client.files).to equal(client.files)
    end
  end

  describe '#groups' do
    it 'returns a GroupsAccessor' do
      expect(client.groups).to be_a(Uploadcare::Client::GroupsAccessor)
    end

    it 'memoizes the accessor' do
      expect(client.groups).to equal(client.groups)
    end
  end

  describe '#uploads' do
    it 'returns an UploadRouter' do
      expect(client.uploads).to be_a(Uploadcare::Operations::UploadRouter)
    end

    it 'memoizes the router' do
      expect(client.uploads).to equal(client.uploads)
    end
  end

  describe '#project' do
    it 'returns a ProjectAccessor' do
      expect(client.project).to be_a(Uploadcare::Client::ProjectAccessor)
    end

    it 'memoizes the accessor' do
      expect(client.project).to equal(client.project)
    end
  end

  describe '#webhooks' do
    it 'returns a WebhooksAccessor' do
      expect(client.webhooks).to be_a(Uploadcare::Client::WebhooksAccessor)
    end

    it 'memoizes the accessor' do
      expect(client.webhooks).to equal(client.webhooks)
    end
  end

  describe '#addons' do
    it 'returns an AddonsAccessor' do
      expect(client.addons).to be_a(Uploadcare::Client::AddonsAccessor)
    end

    it 'memoizes the accessor' do
      expect(client.addons).to equal(client.addons)
    end
  end

  describe '#file_metadata' do
    it 'returns a FileMetadataAccessor' do
      expect(client.file_metadata).to be_a(Uploadcare::Client::FileMetadataAccessor)
    end

    it 'memoizes the accessor' do
      expect(client.file_metadata).to equal(client.file_metadata)
    end
  end

  describe '#conversions' do
    it 'returns a ConversionsAccessor' do
      expect(client.conversions).to be_a(Uploadcare::Client::ConversionsAccessor)
    end

    it 'provides documents sub-accessor' do
      expect(client.conversions.documents).to be_a(Uploadcare::Client::DocumentConversionsAccessor)
    end

    it 'provides videos sub-accessor' do
      expect(client.conversions.videos).to be_a(Uploadcare::Client::VideoConversionsAccessor)
    end
  end

  describe 'DocumentConversionsAccessor delegation' do
    let(:rest) { instance_double(Uploadcare::Api::Rest) }
    let(:document_conversions) { instance_double(Uploadcare::Api::Rest::DocumentConversions) }
    let(:api_instance) { instance_double(Uploadcare::Client::Api, rest: rest) }

    before do
      allow(client).to receive(:api).and_return(api_instance)
      allow(rest).to receive(:document_conversions).and_return(document_conversions)
    end

    it 'delegates status without constructing a throwaway resource in the accessor' do
      allow(document_conversions).to receive(:status)
        .with(token: 'doc-token', request_options: {})
        .and_return(Uploadcare::Result.success({ 'status' => 'finished' }))

      result = client.conversions.documents.status(token: 'doc-token')
      expect(result).to be_a(Uploadcare::Resources::DocumentConversion)
      expect(result.status).to eq('finished')
    end

    it 'delegates info through the resource class' do
      allow(document_conversions).to receive(:info)
        .with(uuid: 'doc-uuid', request_options: {})
        .and_return(Uploadcare::Result.success({ 'format' => 'pdf' }))

      result = client.conversions.documents.info(uuid: 'doc-uuid')
      expect(result).to be_a(Uploadcare::Resources::DocumentConversion)
      expect(result.format).to eq('pdf')
    end
  end

  describe 'VideoConversionsAccessor delegation' do
    let(:rest) { instance_double(Uploadcare::Api::Rest) }
    let(:video_conversions) { instance_double(Uploadcare::Api::Rest::VideoConversions) }
    let(:api_instance) { instance_double(Uploadcare::Client::Api, rest: rest) }

    before do
      allow(client).to receive(:api).and_return(api_instance)
      allow(rest).to receive(:video_conversions).and_return(video_conversions)
    end

    it 'delegates status through the resource class' do
      allow(video_conversions).to receive(:status)
        .with(token: 'video-token', request_options: {})
        .and_return(Uploadcare::Result.success({ 'status' => 'processing' }))

      result = client.conversions.videos.status(token: 'video-token')
      expect(result).to be_a(Uploadcare::Resources::VideoConversion)
      expect(result.status).to eq('processing')
    end
  end

  describe '#upload' do
    it 'delegates to uploads.upload' do
      uploads = instance_double(Uploadcare::Operations::UploadRouter)
      allow(client).to receive(:uploads).and_return(uploads)

      expect(uploads).to receive(:upload).with('https://example.com/img.jpg', request_options: {})
      client.upload('https://example.com/img.jpg')
    end
  end

  describe 'FilesAccessor delegation' do
    let(:rest) { instance_double(Uploadcare::Api::Rest) }
    let(:rest_files) { instance_double(Uploadcare::Api::Rest::Files) }
    let(:api_instance) { instance_double(Uploadcare::Client::Api, rest: rest) }
    let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

    before do
      allow(client).to receive(:api).and_return(api_instance)
      allow(rest).to receive(:files).and_return(rest_files)
    end

    it 'delegates find to Resources::File.find' do
      allow(rest_files).to receive(:info)
        .and_return(Uploadcare::Result.success({ 'uuid' => file_uuid }))

      result = client.files.find(uuid: file_uuid)
      expect(result).to be_a(Uploadcare::Resources::File)
    end

    it 'delegates list to Resources::File.list' do
      allow(rest_files).to receive(:list)
        .and_return(Uploadcare::Result.success({
                                                 'results' => [], 'next' => nil, 'previous' => nil,
                                                 'per_page' => 10, 'total' => 0
                                               }))

      result = client.files.list
      expect(result).to be_a(Uploadcare::Collections::Paginated)
    end

    it 'delegates batch_store to Resources::File.batch_store' do
      allow(rest_files).to receive(:batch_store)
        .and_return(Uploadcare::Result.success({ 'status' => 'ok', 'result' => [], 'problems' => {} }))

      result = client.files.batch_store(uuids: [file_uuid])
      expect(result).to be_a(Uploadcare::Collections::BatchResult)
    end

    it 'delegates batch_delete to Resources::File.batch_delete' do
      allow(rest_files).to receive(:batch_delete)
        .and_return(Uploadcare::Result.success({ 'status' => 'ok', 'result' => [], 'problems' => {} }))

      result = client.files.batch_delete(uuids: [file_uuid])
      expect(result).to be_a(Uploadcare::Collections::BatchResult)
    end

    it 'delegates copy_to_local to Resources::File.local_copy' do
      allow(rest_files).to receive(:local_copy)
        .and_return(Uploadcare::Result.success({ 'result' => { 'uuid' => file_uuid } }))

      result = client.files.copy_to_local(source: file_uuid)
      expect(result).to be_a(Uploadcare::Resources::File)
    end

    it 'delegates copy_to_remote to Resources::File.remote_copy' do
      allow(rest_files).to receive(:remote_copy)
        .and_return(Uploadcare::Result.success({ 'result' => 's3://bucket/file' }))

      result = client.files.copy_to_remote(source: file_uuid, target: 'my-storage')
      expect(result).to eq('s3://bucket/file')
    end
  end

  describe 'GroupsAccessor delegation' do
    let(:rest) { instance_double(Uploadcare::Api::Rest) }
    let(:rest_groups) { instance_double(Uploadcare::Api::Rest::Groups) }
    let(:upload_api) { instance_double(Uploadcare::Api::Upload) }
    let(:upload_groups) { double('upload_groups') }
    let(:api_instance) { instance_double(Uploadcare::Client::Api, rest: rest, upload: upload_api) }

    before do
      allow(client).to receive(:api).and_return(api_instance)
      allow(rest).to receive(:groups).and_return(rest_groups)
      allow(upload_api).to receive(:groups).and_return(upload_groups)
    end

    it 'delegates find to Resources::Group.find' do
      allow(rest_groups).to receive(:info)
        .and_return(Uploadcare::Result.success({ 'id' => 'group-id~3' }))

      result = client.groups.find(group_id: 'group-id~3')
      expect(result).to be_a(Uploadcare::Resources::Group)
    end

    it 'delegates list to Resources::Group.list' do
      allow(rest_groups).to receive(:list)
        .and_return(Uploadcare::Result.success({
                                                 'results' => [], 'next' => nil, 'previous' => nil,
                                                 'per_page' => 10, 'total' => 0
                                               }))

      result = client.groups.list
      expect(result).to be_a(Uploadcare::Collections::Paginated)
    end

    it 'delegates create to Resources::Group.create' do
      allow(upload_groups).to receive(:create)
        .and_return(Uploadcare::Result.success({ 'id' => 'group-id~2' }))

      result = client.groups.create(%w[uuid-1 uuid-2])
      expect(result).to be_a(Uploadcare::Resources::Group)
    end
  end

  describe 'ProjectAccessor delegation' do
    let(:rest) { instance_double(Uploadcare::Api::Rest) }
    let(:rest_project) { instance_double(Uploadcare::Api::Rest::Project) }
    let(:api_instance) { instance_double(Uploadcare::Client::Api, rest: rest) }

    before do
      allow(client).to receive(:api).and_return(api_instance)
      allow(rest).to receive(:project).and_return(rest_project)
    end

    it 'delegates current to Resources::Project.current' do
      allow(rest_project).to receive(:show)
        .and_return(Uploadcare::Result.success({ 'name' => 'Test' }))

      result = client.project.current
      expect(result).to be_a(Uploadcare::Resources::Project)
      expect(result.name).to eq('Test')
    end
  end

  describe 'WebhooksAccessor delegation' do
    let(:rest) { instance_double(Uploadcare::Api::Rest) }
    let(:rest_webhooks) { instance_double(Uploadcare::Api::Rest::Webhooks) }
    let(:api_instance) { instance_double(Uploadcare::Client::Api, rest: rest) }

    before do
      allow(client).to receive(:api).and_return(api_instance)
      allow(rest).to receive(:webhooks).and_return(rest_webhooks)
    end

    it 'delegates list to Resources::Webhook.list' do
      allow(rest_webhooks).to receive(:list)
        .and_return(Uploadcare::Result.success([]))

      result = client.webhooks.list
      expect(result).to be_an(Array)
    end

    it 'delegates create to Resources::Webhook.create' do
      allow(rest_webhooks).to receive(:create)
        .and_return(Uploadcare::Result.success({
                                                 'id' => 1, 'target_url' => 'https://example.com',
                                                 'event' => 'file.uploaded', 'is_active' => true
                                               }))

      result = client.webhooks.create(target_url: 'https://example.com')
      expect(result).to be_a(Uploadcare::Resources::Webhook)
    end

    it 'delegates update to Resources::Webhook.update' do
      allow(rest_webhooks).to receive(:update)
        .and_return(Uploadcare::Result.success({ 'id' => 1, 'target_url' => 'https://new.com' }))

      result = client.webhooks.update(id: 1, target_url: 'https://new.com')
      expect(result).to be_a(Uploadcare::Resources::Webhook)
    end

    it 'delegates delete to Resources::Webhook.delete' do
      allow(rest_webhooks).to receive(:delete)
        .and_return(Uploadcare::Result.success(nil))

      expect {
        client.webhooks.delete(target_url: 'https://example.com')
      }.not_to raise_error
    end
  end

  describe 'AddonsAccessor delegation' do
    let(:rest) { instance_double(Uploadcare::Api::Rest) }
    let(:rest_addons) { instance_double(Uploadcare::Api::Rest::Addons) }
    let(:api_instance) { instance_double(Uploadcare::Client::Api, rest: rest) }
    let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

    before do
      allow(client).to receive(:api).and_return(api_instance)
      allow(rest).to receive(:addons).and_return(rest_addons)
    end

    it 'delegates aws_rekognition_detect_labels' do
      allow(rest_addons).to receive(:aws_rekognition_detect_labels)
        .and_return(Uploadcare::Result.success({ 'request_id' => 'req-1' }))

      result = client.addons.aws_rekognition_detect_labels(uuid: file_uuid)
      expect(result).to be_a(Uploadcare::Resources::AddonExecution)
    end

    it 'delegates uc_clamav_virus_scan' do
      allow(rest_addons).to receive(:uc_clamav_virus_scan)
        .and_return(Uploadcare::Result.success({ 'request_id' => 'req-2' }))

      result = client.addons.uc_clamav_virus_scan(uuid: file_uuid)
      expect(result).to be_a(Uploadcare::Resources::AddonExecution)
    end

    it 'delegates remove_bg' do
      allow(rest_addons).to receive(:remove_bg)
        .and_return(Uploadcare::Result.success({ 'request_id' => 'req-3' }))

      result = client.addons.remove_bg(uuid: file_uuid)
      expect(result).to be_a(Uploadcare::Resources::AddonExecution)
    end
  end

  describe 'FileMetadataAccessor delegation' do
    let(:rest) { instance_double(Uploadcare::Api::Rest) }
    let(:rest_metadata) { instance_double(Uploadcare::Api::Rest::FileMetadata) }
    let(:api_instance) { instance_double(Uploadcare::Client::Api, rest: rest) }
    let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

    before do
      allow(client).to receive(:api).and_return(api_instance)
      allow(rest).to receive(:file_metadata).and_return(rest_metadata)
    end

    it 'delegates index' do
      allow(rest_metadata).to receive(:index)
        .and_return(Uploadcare::Result.success({ 'key' => 'val' }))

      result = client.file_metadata.index(uuid: file_uuid)
      expect(result).to eq({ 'key' => 'val' })
    end

    it 'delegates show' do
      allow(rest_metadata).to receive(:show)
        .and_return(Uploadcare::Result.success('val'))

      result = client.file_metadata.show(uuid: file_uuid, key: 'key')
      expect(result).to eq('val')
    end

    it 'delegates update' do
      allow(rest_metadata).to receive(:update)
        .and_return(Uploadcare::Result.success('new-val'))

      result = client.file_metadata.update(uuid: file_uuid, key: 'key', value: 'new-val')
      expect(result).to eq('new-val')
    end

    it 'delegates delete' do
      allow(rest_metadata).to receive(:delete)
        .and_return(Uploadcare::Result.success(nil))

      expect {
        client.file_metadata.delete(uuid: file_uuid, key: 'key')
      }.not_to raise_error
    end
  end
end
