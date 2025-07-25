# frozen_string_literal: true

module Uploadcare
  class Api
    attr_reader :config

    def initialize(config = nil)
      @config = config || Uploadcare.configuration
    end

    # File operations
    def file(uuid)
      File.new({ uuid: uuid }, config).info
    end

    def file_list(options = {})
      File.list(options, config)
    end

    def store_file(uuid)
      File.new({ uuid: uuid }, config).store
    end

    def delete_file(uuid)
      File.new({ uuid: uuid }, config).delete
    end

    def batch_store(uuids)
      File.batch_store(uuids, config)
    end

    def batch_delete(uuids)
      File.batch_delete(uuids, config)
    end

    def local_copy(source, options = {})
      File.local_copy(source, options, config)
    end

    def remote_copy(source, target, options = {})
      File.remote_copy(source, target, options, config)
    end

    # Upload operations
    def upload(input, options = {})
      Uploader.upload(input, options, config)
    end

    def upload_file(file, options = {})
      Uploader.upload_file(file, options, config)
    end

    def upload_files(files, options = {})
      Uploader.upload_files(files, options, config)
    end

    def upload_from_url(url, options = {})
      Uploader.upload_from_url(url, options, config)
    end

    def check_upload_status(token)
      Uploader.check_upload_status(token, config)
    end

    # Group operations
    def group(uuid)
      Group.new({ id: uuid }, config).info
    end

    def group_list(options = {})
      Group.list(options, config)
    end

    def create_group(files, options = {})
      Group.create(files, options, config)
    end

    def store_group(uuid)
      Group.new({ id: uuid }, config).store
    end

    def delete_group(uuid)
      Group.new({ id: uuid }, config).delete
    end

    # Project operations
    def project
      Project.info(config)
    end

    # Webhook operations
    def create_webhook(target_url, options = {})
      Webhook.create({ target_url: target_url }.merge(options), config)
    end

    def list_webhooks(options = {})
      Webhook.list(options, config)
    end

    def update_webhook(id, options = {})
      webhook = Webhook.new({ id: id }, config)
      webhook.update(options)
    end

    def delete_webhook(target_url)
      Webhook.delete(target_url, config)
    end

    # Document conversion
    def convert_document(paths, options = {})
      DocumentConverter.convert(paths, options, config)
    end

    def document_conversion_status(token)
      DocumentConverter.status(token, config)
    end

    # Video conversion
    def convert_video(paths, options = {})
      VideoConverter.convert(paths, options, config)
    end

    def video_conversion_status(token)
      VideoConverter.status(token, config)
    end

    # Add-ons operations
    def execute_addon(addon_name, target, options = {})
      AddOns.execute(addon_name, target, options, config)
    end

    def check_addon_status(addon_name, request_id)
      AddOns.status(addon_name, request_id, config)
    end

    # File metadata operations
    def file_metadata(uuid)
      FileMetadata.index(uuid, config)
    end

    def get_file_metadata(uuid, key)
      FileMetadata.show(uuid, key, config)
    end

    def update_file_metadata(uuid, key, value)
      FileMetadata.update(uuid, key, value, config)
    end

    def delete_file_metadata(uuid, key)
      FileMetadata.delete(uuid, key, config)
    end
  end
end
