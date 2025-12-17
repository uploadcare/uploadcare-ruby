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

    # Gets file info by UUID (v4.4.3 compatibility)
    # @param uuid [String] The file UUID
    # @param config [Uploadcare::Configuration] Configuration object
    # @return [Uploadcare::File] The file object with full info
    def self.info(uuid, config = Uploadcare.configuration)
      file_client = Uploadcare::FileClient.new(config)
      response = file_client.info(uuid)
      new(response, config)
    end

    # Gets file info by UUID with optional parameters (v4.4.3 compatibility)
    # @param uuid [String] The file UUID
    # @param params [Hash] Optional parameters like include: "appdata"
    # @param config [Uploadcare::Configuration] Configuration object
    # @return [Uploadcare::File] The file object with full info
    def self.file(uuid, params = {}, config = Uploadcare.configuration)
      file_client = Uploadcare::FileClient.new(config)
      response = file_client.info(uuid, params)
      new(response, config)
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
        status: response['status'],
        result: response['result'],
        problems: response['problems'] || {},
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
        status: response['status'],
        result: response['result'],
        problems: response['problems'] || {},
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

    # Convert this file to a document format
    # @param params [Hash] Conversion parameters (format, page, etc.)
    # @param options [Hash] Optional parameters (store, etc.)
    # @return [Uploadcare::File] The converted file
    def convert_document(params = {}, options = {})
      convert_file(params, DocumentConverter, options)
    end

    # Convert this file to a video format
    # @param params [Hash] Conversion parameters (format, quality, cut, size, thumb, etc.)
    # @param options [Hash] Optional parameters (store, etc.)
    # @return [Uploadcare::File] The converted file
    def convert_video(params = {}, options = {})
      convert_file(params, VideoConverter, options)
    end

    # Gets file's uuid - even if it's only initialized with url (v4.4.3 compatibility)
    # @return [String]
    def uuid
      return @uuid if @uuid

      # If initialized from URL, extract UUID
      if @url
        extracted_uuid = @url.gsub('https://ucarecdn.com/', '')
        extracted_uuid.gsub!(%r{/.*}, '')
        extracted_uuid
      else
        @uuid
      end
    end

    # Gets file's id (alias for uuid for compatibility)
    # @return [String]
    def id
      uuid
    end

    # Returns file's CDN URL (v4.4.3 compatibility)
    # @return [String] The CDN URL for the file
    def cdn_url
      return @url if @url

      # Generate CDN URL from uuid and config
      "#{@config.cdn_base.call}#{uuid}/"
    end

    # Loads file metadata, if it's initialized with url or uuid (v4.4.3 compatibility)
    # @return [Uploadcare::File]
    def load
      response = info
      assign_attributes(response.instance_variables.each_with_object({}) do |var, hash|
        hash[var.to_s.delete('@').to_sym] = response.instance_variable_get(var)
      end)
      self
    end

    private

    # General file conversion method (v4.4.3 compatibility)
    # @param params [Hash] Conversion parameters
    # @param converter [Class] Converter class to use
    # @param options [Hash] Optional parameters
    # @return [Uploadcare::File]
    def convert_file(params, converter, options = {})
      validate_convert_params(params)
      prepared_params = prepare_convert_params(params)
      result = perform_conversion(converter, prepared_params, options)
      process_convert_result(result)
    end

    def validate_convert_params(params)
      error_class = if defined?(Uploadcare::Exception::ConversionError)
                      Uploadcare::Exception::ConversionError
                    else
                      ArgumentError
                    end
      raise error_class, 'The first argument must be a Hash' unless params.is_a?(Hash)
    end

    def prepare_convert_params(params)
      params_with_symbolized_keys = params.transform_keys(&:to_sym)
      params_with_symbolized_keys[:uuid] = uuid
      params_with_symbolized_keys
    end

    def perform_conversion(converter, params, options)
      if converter.respond_to?(:convert_document)
        converter.convert_document(params, options, @config)
      elsif converter.respond_to?(:convert)
        converter.convert(params, options, @config)
      else
        raise "Converter #{converter.name} does not respond to convert_document or convert"
      end
    end

    def process_convert_result(result)
      return process_monads_result(result) if result.respond_to?(:success?) && result.success?
      return process_hash_result(result) if result.is_a?(Hash) && result['result']&.first

      result
    end

    def process_monads_result(result)
      uuid_from_result = result.value![:result].first[:uuid]
      self.class.info(uuid_from_result)
    end

    def process_hash_result(result)
      result_data = result['result'].first
      return self.class.info(result_data['uuid']) if result_data['uuid']

      result
    end
  end
end
