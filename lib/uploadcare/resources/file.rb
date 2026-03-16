# frozen_string_literal: true

# File resource representing an uploaded file in Uploadcare.
#
# Provides both class methods (find, list, upload, batch operations, copy)
# and instance methods (store, delete, reload, convert) for working with files.
#
# @example Finding a file
#   file = Uploadcare::File.find(uuid: "file-uuid")
#   file.original_filename  # => "photo.jpg"
#
# @example Uploading
#   file = Uploadcare::File.upload(File.open("photo.jpg"), store: true)
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File
class Uploadcare::Resources::File < Uploadcare::Resources::BaseResource
  ATTRIBUTES = %i[
    datetime_removed datetime_stored datetime_uploaded is_image is_ready mime_type original_file_url
    original_filename size url uuid variations content_info metadata appdata source
  ].freeze

  attr_writer :uuid
  attr_accessor :datetime_removed, :datetime_stored, :datetime_uploaded, :is_image, :is_ready, :mime_type,
                :original_file_url, :original_filename, :size, :url, :variations, :content_info,
                :metadata, :appdata, :source

  # --- Class methods ---

  # Find a file by UUID.
  #
  # @param uuid [String] File UUID
  # @param params [Hash] Optional parameters (e.g., include: "appdata")
  # @param client [Uploadcare::Client, nil] Client instance
  # @param config [Uploadcare::Configuration] Configuration fallback
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Resources::File]
  def self.find(uuid:, params: {}, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    response = Uploadcare::Result.unwrap(
      resolved_client.api.rest.files.info(uuid: uuid, params: params, request_options: request_options)
    )
    new(response, resolved_client)
  end

  class << self
    alias retrieve find
    alias info find
  end

  # List files with optional filtering and pagination.
  #
  # @param options [Hash] Query parameters (limit, ordering, etc.)
  # @param client [Uploadcare::Client, nil] Client instance
  # @param config [Uploadcare::Configuration] Configuration fallback
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Collections::Paginated]
  def self.list(options: {}, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    response = Uploadcare::Result.unwrap(
      resolved_client.api.rest.files.list(params: options, request_options: request_options)
    )

    files = response['results'].map { |data| new(data, resolved_client) }

    Uploadcare::Collections::Paginated.new(
      resources: files,
      next_page: response['next'],
      previous_page: response['previous'],
      per_page: response['per_page'],
      total: response['total'],
      api_client: resolved_client.api.rest.files,
      resource_class: self,
      client: resolved_client
    )
  end

  # Upload a single file.
  #
  # @param file [File, IO] File to upload
  # @param client [Uploadcare::Client, nil] Client instance
  # @param config [Uploadcare::Configuration] Configuration fallback
  # @param options [Hash] Upload options
  # @return [Uploadcare::Resources::File]
  def self.upload(file, client: nil, config: Uploadcare.configuration, request_options: {}, **options)
    resolved_client = resolve_client(client: client, config: config)
    resolved_client.uploads.upload_file(file: file, request_options: request_options, **options)
  end

  # Upload multiple files.
  #
  # @param files [Array<File, IO>] Files to upload
  # @param client [Uploadcare::Client, nil] Client instance
  # @param config [Uploadcare::Configuration] Configuration fallback
  # @param options [Hash] Upload options
  # @return [Array<Uploadcare::Resources::File>]
  def self.upload_many(files, client: nil, config: Uploadcare.configuration, request_options: {}, **options)
    resolved_client = resolve_client(client: client, config: config)
    resolved_client.uploads.upload_files(files: files, request_options: request_options, **options)
  end

  # Upload a file from URL.
  #
  # @param url [String] Source URL
  # @param client [Uploadcare::Client, nil] Client instance
  # @param config [Uploadcare::Configuration] Configuration fallback
  # @param options [Hash] Upload options
  # @return [Uploadcare::Resources::File]
  def self.upload_url(url, client: nil, config: Uploadcare.configuration, request_options: {}, **options)
    resolved_client = resolve_client(client: client, config: config)
    resolved_client.uploads.upload_from_url(url: url, request_options: request_options, **options)
  end

  class << self
    alias upload_from_url upload_url
  end

  # Batch store files.
  #
  # @param uuids [Array<String>] File UUIDs to store
  # @param client [Uploadcare::Client, nil] Client instance
  # @param config [Uploadcare::Configuration] Configuration fallback
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Collections::BatchResult]
  def self.batch_store(uuids:, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    response = Uploadcare::Result.unwrap(
      resolved_client.api.rest.files.batch_store(uuids: uuids, request_options: request_options)
    )
    normalized = response.transform_keys(&:to_s)

    Uploadcare::Collections::BatchResult.new(
      status: normalized['status'],
      result: normalized['result'],
      problems: normalized['problems'] || {},
      client: resolved_client
    )
  end

  # Batch delete files.
  #
  # @param uuids [Array<String>] File UUIDs to delete
  # @param client [Uploadcare::Client, nil] Client instance
  # @param config [Uploadcare::Configuration] Configuration fallback
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Collections::BatchResult]
  def self.batch_delete(uuids:, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    response = Uploadcare::Result.unwrap(
      resolved_client.api.rest.files.batch_delete(uuids: uuids, request_options: request_options)
    )
    normalized = response.transform_keys(&:to_s)

    Uploadcare::Collections::BatchResult.new(
      status: normalized['status'],
      result: normalized['result'],
      problems: normalized['problems'] || {},
      client: resolved_client
    )
  end

  # Copy a file to local storage (class method).
  #
  # @param source [String] CDN URL or UUID
  # @param options [Hash] Optional parameters
  # @return [Uploadcare::Resources::File]
  def self.local_copy(source:, options: {}, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    response = Uploadcare::Result.unwrap(
      resolved_client.api.rest.files.local_copy(source: source, options: options, request_options: request_options)
    )
    new(response['result'], resolved_client)
  end

  class << self
    alias copy_to_local local_copy
  end

  # Copy a file to remote storage (class method).
  #
  # @param source [String] CDN URL or UUID
  # @param target [String] Custom storage name
  # @param options [Hash] Optional parameters
  # @return [String] URL of the copied file
  def self.remote_copy(source:, target:, options: {}, client: nil, config: Uploadcare.configuration,
                       request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    response = Uploadcare::Result.unwrap(
      resolved_client.api.rest.files.remote_copy(
        source: source, target: target, options: options, request_options: request_options
      )
    )
    response['result']
  end

  class << self
    alias copy_to_remote remote_copy
  end

  # --- Instance methods ---

  # Store this file, making it permanently available.
  #
  # @param request_options [Hash] Request options
  # @return [self]
  def store(request_options: {})
    response = Uploadcare::Result.unwrap(client.api.rest.files.store(uuid: uuid, request_options: request_options))
    assign_attributes(response)
    self
  end

  # Delete this file.
  #
  # @param request_options [Hash] Request options
  # @return [self]
  def delete(request_options: {})
    response = Uploadcare::Result.unwrap(client.api.rest.files.delete(uuid: uuid, request_options: request_options))
    assign_attributes(response)
    self
  end

  # Reload file information from the API.
  #
  # @param params [Hash] Optional parameters
  # @param request_options [Hash] Request options
  # @return [self]
  def reload(params: {}, request_options: {})
    response = Uploadcare::Result.unwrap(
      client.api.rest.files.info(uuid: uuid, params: params, request_options: request_options)
    )
    assign_attributes(response)
    self
  end
  alias load reload

  # Copy this file to local storage.
  #
  # @param options [Hash] Optional parameters
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Resources::File] The copied file
  def copy_to_local(options: {}, request_options: {})
    response = Uploadcare::Result.unwrap(
      client.api.rest.files.local_copy(source: uuid, options: options, request_options: request_options)
    )
    self.class.new(response['result'], client)
  end
  alias local_copy copy_to_local

  # Copy this file to remote storage.
  #
  # @param target [String] Custom storage name
  # @param options [Hash] Optional parameters
  # @param request_options [Hash] Request options
  # @return [String] URL of the copied file
  def copy_to_remote(target:, options: {}, request_options: {})
    response = Uploadcare::Result.unwrap(
      client.api.rest.files.remote_copy(
        source: uuid, target: target, options: options, request_options: request_options
      )
    )
    response['result']
  end
  alias remote_copy copy_to_remote

  # Convert this file to a document format.
  #
  # @param params [Hash] Conversion parameters (:format, etc.)
  # @param options [Hash] Optional parameters (:store, etc.)
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Resources::File] The converted file
  def convert_to_document(params: {}, options: {}, request_options: {})
    convert_file(params, Uploadcare::Resources::DocumentConversion, options, request_options: request_options)
  end

  # Convert this file to a video format.
  #
  # @param params [Hash] Conversion parameters (:format, :quality, etc.)
  # @param options [Hash] Optional parameters (:store, etc.)
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Resources::File] The converted file
  def convert_to_video(params: {}, options: {}, request_options: {})
    convert_file(params, Uploadcare::Resources::VideoConversion, options, request_options: request_options)
  end

  # Returns the file UUID, extracting from URL if needed.
  #
  # @return [String, nil]
  def uuid
    return @uuid if @uuid

    source = @url || @original_file_url
    return @uuid unless source

    @uuid = source[/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/]
  end

  # Returns the CDN URL for this file.
  #
  # @return [String]
  def cdn_url
    return @url if @url

    "#{config.cdn_base}#{uuid}/"
  end

  private

  def convert_file(params, converter, options = {}, request_options: {})
    raise ArgumentError, 'The first argument must be a Hash' unless params.is_a?(Hash)

    params_with_symbolized_keys = params.transform_keys(&:to_sym)
    params_with_symbolized_keys[:uuid] = uuid

    result = if converter.respond_to?(:convert_document)
               converter.convert_document(
                 params: params_with_symbolized_keys, options: options, config: config,
                 request_options: request_options
               )
             elsif converter.respond_to?(:convert)
               converter.convert(
                 params: params_with_symbolized_keys, options: options, config: config,
                 request_options: request_options
               )
             else
               raise Uploadcare::Exception::ConversionError,
                     "Converter #{converter.name} does not respond to convert_document or convert"
             end

    process_convert_result(result, request_options: request_options)
  end

  def process_convert_result(result, request_options: {})
    if result.is_a?(Hash) && result['result']&.first
      return process_hash_result(result, request_options: request_options)
    end

    if result.respond_to?(:result) && result.result.is_a?(Array) && result.result.first.is_a?(Hash)
      return process_hash_result({ 'result' => result.result }, request_options: request_options)
    end

    result
  end

  def process_hash_result(result, request_options: {})
    result_data = result['result'].first
    if result_data['uuid']
      return self.class.find(uuid: result_data['uuid'], client: client, request_options: request_options)
    end

    result
  end
end
