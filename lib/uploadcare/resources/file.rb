# frozen_string_literal: true

module Uploadcare
  class File < BaseResource
    ATTRIBUTES = %i[
      datetime_removed datetime_stored datetime_uploaded is_image is_ready mime_type original_file_url
      original_filename size url uuid variations content_info metadata appdata source
    ].freeze

    attr_accessor(*ATTRIBUTES)

    def initialize(attributes = {}, config = Uploadcare.configuration)
      super
      @file_client = Uploadcare::FileClient.new(config)
    end

    # This method returns a list of Files
    # This is a paginated FileList, so all pagination methods apply
    # @param options [Hash] Optional parameters
    # @param config [Uploadcare::Configuration] Configuration object
    # @return [Uploadcare::FileList]
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesList
    def self.list(options = {}, config = Uploadcare.configuration)
      file_client = Uploadcare::FileClient.new(config)
      response = file_client.list(options)

      files = response['results'].map do |file_data|
        new(file_data, config)
      end

      PaginatedCollection.new(
        resources: files,
        next_page: response['next'],
        previous_page: response['previous'],
        per_page: response['per_page'],
        total: response['total'],
        client: file_client,
        resource_class: self.class
      )
    end

    # Stores the file, making it permanently available
    # @return [Uploadcare::File] The updated File instance
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/storeFile
    def store
      response = @file_client.store(uuid)

      assign_attributes(response)
      self
    end

    # Removes individual files. Returns file info.
    # @return [Uploadcare::File] The deleted File instance
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/deleteFileStorage
    def delete
      response = @file_client.delete(uuid)

      assign_attributes(response)
      self
    end

    # Get File information by its UUID (immutable)
    # @return [Uploadcare::File] The File instance
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/fileinfo
    def info(params = {})
      response = @file_client.info(uuid, params)

      assign_attributes(response)
      self
    end

    # Copies this file to local storage
    # @param options [Hash] Optional parameters
    # @return [Uploadcare::File] The copied file instance
    def local_copy(options = {})
      response = @file_client.local_copy(uuid, options)
      file_data = response['result']
      self.class.new(file_data, @config)
    end

    # Copies this file to remote storage
    # @param target [String] The name of the custom storage
    # @param options [Hash] Optional parameters
    # @return [String] The URL of the copied file in the remote storage
    def remote_copy(target, options = {})
      response = @file_client.remote_copy(uuid, target, options)
      response['result']
    end

    # Batch store files, making them permanently available
    # @param uuids [Array<String>] List of file UUIDs to store
    # @param config [Uploadcare::Configuration] Configuration object
    # @return [Uploadcare::BatchFileResult]
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesStoring
    def self.batch_store(uuids, config = Uploadcare.configuration)
      file_client = Uploadcare::FileClient.new(config)
      response = file_client.batch_store(uuids)

      BatchFileResult.new(
        status: response[:status],
        result: response[:result],
        problems: response[:problems] || {},
        config: config
      )
    end

    # Batch delete files, removing them permanently
    # @param uuids [Array<String>] List of file UUIDs to delete
    # @param config [Uploadcare::Configuration] Configuration object
    # @return [Uploadcare::BatchFileResult]
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesDelete
    def self.batch_delete(uuids, config = Uploadcare.configuration)
      file_client = Uploadcare::FileClient.new(config)
      response = file_client.batch_delete(uuids)

      BatchFileResult.new(
        status: response[:status],
        result: response[:result],
        problems: response[:problems] || {},
        config: config
      )
    end

    # Copies a file to local storage
    # @param source [String] The CDN URL or UUID of the file to copy
    # @param options [Hash] Optional parameters
    # @param config [Uploadcare::Configuration] Configuration object
    # @return [Uploadcare::File] The copied file
    def self.local_copy(source, options = {}, config = Uploadcare.configuration)
      file_client = Uploadcare::FileClient.new(config)
      response = file_client.local_copy(source, options)
      file_data = response['result']
      new(file_data, config)
    end

    # Copies a file to remote storage
    # @param source [String] The CDN URL or UUID of the file to copy
    # @param target [String] The name of the custom storage
    # @param options [Hash] Optional parameters
    # @param config [Uploadcare::Configuration] Configuration object
    # @return [String] The URL of the copied file in the remote storage
    def self.remote_copy(source, target, options = {}, config = Uploadcare.configuration)
      file_client = Uploadcare::FileClient.new(config)
      response = file_client.remote_copy(source, target, options)
      response['result']
    end
  end
end
