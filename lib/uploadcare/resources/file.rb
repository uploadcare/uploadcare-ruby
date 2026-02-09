# frozen_string_literal: true

# File resource.
class Uploadcare::File < Uploadcare::BaseResource
  # File attributes exposed by the API.
  ATTRIBUTES = %i[
    datetime_removed datetime_stored datetime_uploaded is_image is_ready mime_type original_file_url
    original_filename size url uuid variations content_info metadata appdata source
  ].freeze

  attr_accessor(*ATTRIBUTES)

  def initialize(attributes = {}, config = Uploadcare.configuration)
    super
    @file_client = Uploadcare::FileClient.new(config: config)
  end

  # Gets file info by UUID
  # @param uuid [String] The file UUID
  # @param config [Uploadcare::Configuration] Configuration object
  # @return [Uploadcare::File] The file object with full info
  def self.info(uuid:, config: Uploadcare.configuration, request_options: {})
    file_client = Uploadcare::FileClient.new(config: config)
    response = Uploadcare::Result.unwrap(file_client.info(uuid: uuid, request_options: request_options))
    new(response, config)
  end

  # Gets file info by UUID with optional parameters
  # @param uuid [String] The file UUID
  # @param params [Hash] Optional parameters like include: "appdata"
  # @param config [Uploadcare::Configuration] Configuration object
  # @return [Uploadcare::File] The file object with full info
  def self.file(uuid:, params: {}, config: Uploadcare.configuration, request_options: {})
    file_client = Uploadcare::FileClient.new(config: config)
    response = Uploadcare::Result.unwrap(file_client.info(uuid: uuid, params: params,
                                                          request_options: request_options))
    new(response, config)
  end

  # This method returns a list of Files
  # This is a paginated FileList, so all pagination methods apply
  # @param options [Hash] Optional parameters
  # @param config [Uploadcare::Configuration] Configuration object
  # @return [Uploadcare::FileList]
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesList
  def self.list(options: {}, config: Uploadcare.configuration, request_options: {})
    file_client = Uploadcare::FileClient.new(config: config)
    response = Uploadcare::Result.unwrap(file_client.list(params: options, request_options: request_options))

    files = response['results'].map do |file_data|
      new(file_data, config)
    end

    Uploadcare::PaginatedCollection.new(
      resources: files,
      next_page: response['next'],
      previous_page: response['previous'],
      per_page: response['per_page'],
      total: response['total'],
      client: file_client,
      resource_class: self
    )
  end

  # Stores the file, making it permanently available
  # @return [Uploadcare::File] The updated File instance
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/storeFile
  def store(request_options: {})
    response = Uploadcare::Result.unwrap(@file_client.store(uuid: uuid, request_options: request_options))

    assign_attributes(response)
    self
  end

  # Removes individual files. Returns file info.
  # @return [Uploadcare::File] The deleted File instance
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/deleteFileStorage
  def delete(request_options: {})
    response = Uploadcare::Result.unwrap(@file_client.delete(uuid: uuid, request_options: request_options))

    assign_attributes(response)
    self
  end

  # Get File information by its UUID (immutable)
  # @return [Uploadcare::File] The File instance
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/fileinfo
  def info(params: {}, request_options: {})
    response = Uploadcare::Result.unwrap(@file_client.info(uuid: uuid, params: params,
                                                           request_options: request_options))

    assign_attributes(response)
    self
  end

  # Copies this file to local storage
  # @param options [Hash] Optional parameters
  # @return [Uploadcare::File] The copied file instance
  def local_copy(options: {}, request_options: {})
    response = Uploadcare::Result.unwrap(@file_client.local_copy(source: uuid, options: options,
                                                                 request_options: request_options))
    file_data = response['result']
    self.class.new(file_data, @config)
  end

  # Copies this file to remote storage
  # @param target [String] The name of the custom storage
  # @param options [Hash] Optional parameters
  # @return [String] The URL of the copied file in the remote storage
  def remote_copy(target:, options: {}, request_options: {})
    response = Uploadcare::Result.unwrap(@file_client.remote_copy(source: uuid, target: target, options: options,
                                                                  request_options: request_options))
    response['result']
  end

  # Batch store files, making them permanently available
  # @param uuids [Array<String>] List of file UUIDs to store
  # @param config [Uploadcare::Configuration] Configuration object
  # @return [Uploadcare::BatchFileResult]
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesStoring
  def self.batch_store(uuids:, config: Uploadcare.configuration, request_options: {})
    file_client = Uploadcare::FileClient.new(config: config)
    response = Uploadcare::Result.unwrap(file_client.batch_store(uuids: uuids, request_options: request_options))

    Uploadcare::BatchFileResult.new(
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
  def self.batch_delete(uuids:, config: Uploadcare.configuration, request_options: {})
    file_client = Uploadcare::FileClient.new(config: config)
    response = Uploadcare::Result.unwrap(file_client.batch_delete(uuids: uuids, request_options: request_options))

    Uploadcare::BatchFileResult.new(
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
  def self.local_copy(source:, options: {}, config: Uploadcare.configuration, request_options: {})
    file_client = Uploadcare::FileClient.new(config: config)
    response = Uploadcare::Result.unwrap(file_client.local_copy(source: source, options: options,
                                                                request_options: request_options))
    file_data = response['result']
    new(file_data, config)
  end

  # Copies a file to remote storage
  # @param source [String] The CDN URL or UUID of the file to copy
  # @param target [String] The name of the custom storage
  # @param options [Hash] Optional parameters
  # @param config [Uploadcare::Configuration] Configuration object
  # @return [String] The URL of the copied file in the remote storage
  def self.remote_copy(source:, target:, options: {}, config: Uploadcare.configuration, request_options: {})
    file_client = Uploadcare::FileClient.new(config: config)
    response = Uploadcare::Result.unwrap(file_client.remote_copy(source: source, target: target, options: options,
                                                                 request_options: request_options))
    response['result']
  end

  # Convert this file to a document format
  # @param params [Hash] Conversion parameters (format, page, etc.)
  # @param options [Hash] Optional parameters (store, etc.)
  # @return [Uploadcare::File] The converted file
  def convert_document(params: {}, options: {}, request_options: {})
    convert_file(params, Uploadcare::DocumentConverter, options, request_options: request_options)
  end

  # Convert this file to a video format
  # @param params [Hash] Conversion parameters (format, quality, cut, size, thumb, etc.)
  # @param options [Hash] Optional parameters (store, etc.)
  # @return [Uploadcare::File] The converted file
  def convert_video(params: {}, options: {}, request_options: {})
    convert_file(params, Uploadcare::VideoConverter, options, request_options: request_options)
  end

  # Returns the file UUID if present, or extracts from URL.
  #
  # @return [String, nil]
  def uuid
    return @uuid if @uuid

    # If initialized from URL, extract UUID
    if @url
      extracted_uuid = @url.gsub('https://ucarecdn.com/', '')
      extracted_uuid.gsub(%r{/.*}, '')
    else
      @uuid
    end
  end

  # Returns the CDN URL for this file.
  #
  # @return [String]
  def cdn_url
    return @url if @url

    # Generate CDN URL from uuid and config
    "#{@config.cdn_base.call}#{uuid}/"
  end

  # Reloads file metadata from the API.
  #
  # @return [Uploadcare::File]
  def load
    info
    self
  end

  private

  def convert_file(params, converter, options = {}, request_options: {})
    validate_convert_params(params)
    prepared_params = prepare_convert_params(params)
    result = perform_conversion(converter, prepared_params, options, request_options: request_options)
    process_convert_result(result, request_options: request_options)
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

  def perform_conversion(converter, params, options, request_options: {})
    if converter.respond_to?(:convert_document)
      converter.convert_document(params: params, options: options, config: @config, request_options: request_options)
    elsif converter.respond_to?(:convert)
      converter.convert(params: params, options: options, config: @config, request_options: request_options)
    else
      raise Uploadcare::Exception::ConversionError,
            "Converter #{converter.name} does not respond to convert_document or convert"
    end
  end

  def process_convert_result(result, request_options: {})
    if result.is_a?(Hash) && result['result']&.first
      return process_hash_result(result,
                                 request_options: request_options)
    end

    if result.respond_to?(:result) && result.result.is_a?(Array) && result.result.first.is_a?(Hash)
      return process_hash_result({ 'result' => result.result }, request_options: request_options)
    end

    result
  end

  def process_hash_result(result, request_options: {})
    result_data = result['result'].first
    if result_data['uuid']
      return self.class.info(uuid: result_data['uuid'], config: @config,
                             request_options: request_options)
    end

    result
  end
end
