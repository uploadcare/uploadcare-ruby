# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'test_public_key',
      secret_key: 'test_secret_key'
    )
  end
  
  subject(:api) { described_class.new(config) }

  describe '#initialize' do
    it 'uses provided configuration' do
      expect(api.config).to eq(config)
    end

    it 'uses default configuration when none provided' do
      api = described_class.new
      expect(api.config).to eq(Uploadcare.configuration)
    end
  end

  describe 'File operations' do
    let(:uuid) { 'file-uuid-123' }
    let(:file_instance) { instance_double(Uploadcare::File) }

    describe '#file' do
      it 'retrieves file info' do
        expect(Uploadcare::File).to receive(:new).with({ uuid: uuid }, config).and_return(file_instance)
        expect(file_instance).to receive(:info).and_return(file_instance)
        
        result = api.file(uuid)
        expect(result).to eq(file_instance)
      end
    end

    describe '#file_list' do
      it 'delegates to File.list' do
        options = { limit: 10 }
        expect(Uploadcare::File).to receive(:list).with(options, config)
        
        api.file_list(options)
      end
    end

    describe '#store_file' do
      it 'stores a file' do
        expect(Uploadcare::File).to receive(:new).with({ uuid: uuid }, config).and_return(file_instance)
        expect(file_instance).to receive(:store).and_return(file_instance)
        
        result = api.store_file(uuid)
        expect(result).to eq(file_instance)
      end
    end

    describe '#delete_file' do
      it 'deletes a file' do
        expect(Uploadcare::File).to receive(:new).with({ uuid: uuid }, config).and_return(file_instance)
        expect(file_instance).to receive(:delete).and_return(file_instance)
        
        result = api.delete_file(uuid)
        expect(result).to eq(file_instance)
      end
    end

    describe '#batch_store' do
      let(:uuids) { ['uuid1', 'uuid2'] }

      it 'delegates to File.batch_store' do
        expect(Uploadcare::File).to receive(:batch_store).with(uuids, config)
        
        api.batch_store(uuids)
      end
    end

    describe '#batch_delete' do
      let(:uuids) { ['uuid1', 'uuid2'] }

      it 'delegates to File.batch_delete' do
        expect(Uploadcare::File).to receive(:batch_delete).with(uuids, config)
        
        api.batch_delete(uuids)
      end
    end

    describe '#local_copy' do
      let(:source) { 'source-uuid' }
      let(:options) { { store: true } }

      it 'delegates to File.local_copy' do
        expect(Uploadcare::File).to receive(:local_copy).with(source, options, config)
        
        api.local_copy(source, options)
      end
    end

    describe '#remote_copy' do
      let(:source) { 'source-uuid' }
      let(:target) { 'custom_storage' }
      let(:options) { { make_public: true } }

      it 'delegates to File.remote_copy' do
        expect(Uploadcare::File).to receive(:remote_copy).with(source, target, options, config)
        
        api.remote_copy(source, target, options)
      end
    end
  end

  describe 'Upload operations' do
    describe '#upload' do
      let(:input) { 'file.jpg' }
      let(:options) { { store: true } }

      it 'delegates to Uploader.upload' do
        expect(Uploadcare::Uploader).to receive(:upload).with(input, options, config)
        
        api.upload(input, options)
      end
    end

    describe '#upload_file' do
      let(:file) { 'file.jpg' }
      let(:options) { { store: true } }

      it 'delegates to Uploader.upload_file' do
        expect(Uploadcare::Uploader).to receive(:upload_file).with(file, options, config)
        
        api.upload_file(file, options)
      end
    end

    describe '#upload_files' do
      let(:files) { ['file1.jpg', 'file2.jpg'] }
      let(:options) { { store: true } }

      it 'delegates to Uploader.upload_files' do
        expect(Uploadcare::Uploader).to receive(:upload_files).with(files, options, config)
        
        api.upload_files(files, options)
      end
    end

    describe '#upload_from_url' do
      let(:url) { 'https://example.com/image.jpg' }
      let(:options) { { store: true } }

      it 'delegates to Uploader.upload_from_url' do
        expect(Uploadcare::Uploader).to receive(:upload_from_url).with(url, options, config)
        
        api.upload_from_url(url, options)
      end
    end

    describe '#check_upload_status' do
      let(:token) { 'upload-token-123' }

      it 'delegates to Uploader.check_upload_status' do
        expect(Uploadcare::Uploader).to receive(:check_upload_status).with(token, config)
        
        api.check_upload_status(token)
      end
    end
  end

  describe 'Group operations' do
    let(:uuid) { 'group-uuid-123' }
    let(:group_instance) { instance_double(Uploadcare::Group) }

    describe '#group' do
      it 'retrieves group info' do
        expect(Uploadcare::Group).to receive(:new).with({ id: uuid }, config).and_return(group_instance)
        expect(group_instance).to receive(:info).and_return(group_instance)
        
        result = api.group(uuid)
        expect(result).to eq(group_instance)
      end
    end

    describe '#group_list' do
      it 'delegates to Group.list' do
        options = { limit: 10 }
        expect(Uploadcare::Group).to receive(:list).with(options, config)
        
        api.group_list(options)
      end
    end

    describe '#create_group' do
      let(:files) { ['uuid1', 'uuid2'] }
      let(:options) { {} }

      it 'delegates to Group.create' do
        expect(Uploadcare::Group).to receive(:create).with(files, options, config)
        
        api.create_group(files, options)
      end
    end
  end

  describe 'Project operations' do
    describe '#project' do
      it 'delegates to Project.info' do
        expect(Uploadcare::Project).to receive(:info).with(config)
        
        api.project
      end
    end
  end

  describe 'Webhook operations' do
    describe '#create_webhook' do
      let(:target_url) { 'https://example.com/webhook' }
      let(:options) { { event: 'file.uploaded' } }

      it 'delegates to Webhook.create' do
        expect(Uploadcare::Webhook).to receive(:create).with({ target_url: target_url }.merge(options), config)
        
        api.create_webhook(target_url, options)
      end
    end

    describe '#list_webhooks' do
      it 'delegates to Webhook.list' do
        options = { limit: 10 }
        expect(Uploadcare::Webhook).to receive(:list).with(options, config)
        
        api.list_webhooks(options)
      end
    end

    describe '#update_webhook' do
      let(:id) { 'webhook-id' }
      let(:options) { { is_active: false } }
      let(:webhook_instance) { instance_double(Uploadcare::Webhook) }

      it 'updates webhook' do
        expect(Uploadcare::Webhook).to receive(:new).with({ id: id }, config).and_return(webhook_instance)
        expect(webhook_instance).to receive(:update).with(options)
        
        api.update_webhook(id, options)
      end
    end

    describe '#delete_webhook' do
      let(:target_url) { 'https://example.com/webhook' }

      it 'delegates to Webhook.delete' do
        expect(Uploadcare::Webhook).to receive(:delete).with(target_url, config)
        
        api.delete_webhook(target_url)
      end
    end
  end

  describe 'Conversion operations' do
    describe '#convert_document' do
      let(:paths) { ['doc-uuid'] }
      let(:options) { { format: 'pdf' } }

      it 'delegates to DocumentConverter.convert' do
        expect(Uploadcare::DocumentConverter).to receive(:convert).with(paths, options, config)
        
        api.convert_document(paths, options)
      end
    end

    describe '#document_conversion_status' do
      let(:token) { 'conversion-token' }

      it 'delegates to DocumentConverter.status' do
        expect(Uploadcare::DocumentConverter).to receive(:status).with(token, config)
        
        api.document_conversion_status(token)
      end
    end

    describe '#convert_video' do
      let(:paths) { ['video-uuid'] }
      let(:options) { { format: 'mp4' } }

      it 'delegates to VideoConverter.convert' do
        expect(Uploadcare::VideoConverter).to receive(:convert).with(paths, options, config)
        
        api.convert_video(paths, options)
      end
    end

    describe '#video_conversion_status' do
      let(:token) { 'conversion-token' }

      it 'delegates to VideoConverter.status' do
        expect(Uploadcare::VideoConverter).to receive(:status).with(token, config)
        
        api.video_conversion_status(token)
      end
    end
  end

  describe 'Add-ons operations' do
    describe '#execute_addon' do
      let(:addon_name) { 'remove_bg' }
      let(:target) { 'file-uuid' }
      let(:options) { { crop: true } }

      it 'delegates to AddOns.execute' do
        expect(Uploadcare::AddOns).to receive(:execute).with(addon_name, target, options, config)
        
        api.execute_addon(addon_name, target, options)
      end
    end

    describe '#check_addon_status' do
      let(:addon_name) { 'remove_bg' }
      let(:request_id) { 'request-id' }

      it 'delegates to AddOns.status' do
        expect(Uploadcare::AddOns).to receive(:status).with(addon_name, request_id, config)
        
        api.check_addon_status(addon_name, request_id)
      end
    end
  end

  describe 'File metadata operations' do
    let(:uuid) { 'file-uuid' }
    let(:key) { 'metadata_key' }
    let(:value) { 'metadata_value' }

    describe '#file_metadata' do
      it 'delegates to FileMetadata.index' do
        expect(Uploadcare::FileMetadata).to receive(:index).with(uuid, config)
        
        api.file_metadata(uuid)
      end
    end

    describe '#get_file_metadata' do
      it 'delegates to FileMetadata.show' do
        expect(Uploadcare::FileMetadata).to receive(:show).with(uuid, key, config)
        
        api.get_file_metadata(uuid, key)
      end
    end

    describe '#update_file_metadata' do
      it 'delegates to FileMetadata.update' do
        expect(Uploadcare::FileMetadata).to receive(:update).with(uuid, key, value, config)
        
        api.update_file_metadata(uuid, key, value)
      end
    end

    describe '#delete_file_metadata' do
      it 'delegates to FileMetadata.delete' do
        expect(Uploadcare::FileMetadata).to receive(:delete).with(uuid, key, config)
        
        api.delete_file_metadata(uuid, key)
      end
    end
  end
end