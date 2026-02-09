# frozen_string_literal: true

# Upload helper for the Upload API.
# @see https://uploadcare.com/api-refs/upload-api/#tag/Upload
class Uploadcare::Uploader < Uploadcare::BaseResource
  def initialize(attributes = {}, config = Uploadcare.configuration)
    super
  end

  # Upload file or group of files from array, File, or url
  #
  # @param object [Array, String, File] upload source
  # @param options [Hash] options for upload
  # @option options [Boolean] :store whether to store file on servers.
  def self.upload(object:, config: Uploadcare.configuration, **options, &)
    if big_file?(object, config)
      multipart_upload(file: object, config: config, **options, &)
    elsif file?(object)
      upload_file(file: object, config: config, **options)
    elsif object.is_a?(Array)
      upload_files(files: object, config: config, **options)
    elsif object.is_a?(String)
      upload_from_url(url: object, config: config, **options)
    else
      raise ArgumentError, "Expected input to be a file/Array/URL, given: `#{object}`"
    end
  end

  # @param file [File]
  # @param options [Hash] options for upload
  # @option options [Boolean] :store whether to store file on servers.
  def self.upload_file(file:, config: Uploadcare.configuration, **options)
    response = Uploadcare::Result.unwrap(uploader_client(config: config).upload_many(files: [file], **options))
    file_name, uuid = response.first

    Uploadcare::File.new({ uuid: uuid, original_filename: file_name }, config)
  end

  # @param files [Array] files to upload
  # @param options [Hash] options for upload
  # @option options [Boolean] :store whether to store file on servers.
  def self.upload_files(files:, config: Uploadcare.configuration, **options)
    response = Uploadcare::Result.unwrap(uploader_client(config: config).upload_many(files: files, **options))

    response.map do |file_name, uuid|
      create_basic_file(uuid: uuid, file_name: file_name, config: config)
    end
  end

  # check the status of the upload request.
  # @param token [String]
  # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload/operation/fromURLUploadStatus
  def self.get_upload_from_url_status(token:, config: Uploadcare.configuration, request_options: {})
    upload_from_url_status(token: token, config: config, request_options: request_options)
  end

  # @param token [String]
  # @return [Hash]
  def self.upload_from_url_status(token:, config: Uploadcare.configuration, request_options: {})
    Uploadcare::Result.unwrap(
      uploader_client(config: config).upload_from_url_status(
        token: token,
        request_options: request_options
      )
    )
  end

  # upload file of size above 10mb (involves multipart upload)
  # @param file [File]
  # @param options [Hash] options for upload
  # @option options [Boolean] :store whether to store file on servers.
  def self.multipart_upload(file:, config: Uploadcare.configuration, request_options: {}, **options, &)
    multipart_uploader_client = Uploadcare::MultipartUploaderClient.new(config: config)
    response = Uploadcare::Result.unwrap(multipart_uploader_client.upload(file: file,
                                                                          request_options: request_options,
                                                                          **options, &))
    return response unless response.is_a?(Hash) && response['uuid']

    Uploadcare::File.new(response, config)
  end

  # upload files from url
  # @param url [String]
  # @param options [Hash] options for upload
  # @option options [Boolean] :store whether to store file on servers.
  def self.upload_from_url(url:, config: Uploadcare.configuration, request_options: {}, **options)
    response = Uploadcare::Result.unwrap(
      uploader_client(config: config).upload_from_url(
        url: url,
        request_options: request_options,
        **options
      )
    )
    return response if options[:async]

    Uploadcare::File.new(response, config)
  end

  # Get information about an uploaded file (without the secret key).
  # @param uuid [String] file UUID
  # @return [Hash]
  def self.file_info(uuid:, config: Uploadcare.configuration, request_options: {})
    Uploadcare::Result.unwrap(uploader_client(config: config).file_info(uuid: uuid, request_options: request_options))
  end

  # Build or fetch a memoized uploader client.
  # @param config [Uploadcare::Configuration]
  # @return [Uploadcare::UploaderClient]
  def self.uploader_client(config: Uploadcare.configuration)
    @uploader_clients ||= {}
    @uploader_clients[config] ||= Uploadcare::UploaderClient.new(config: config)
  end

  # @param object [File]
  # @return [Boolean]
  def self.file?(object)
    object.respond_to?(:path) && ::File.exist?(object.path)
  end

  # @param object [File]
  # @return [Boolean]
  def self.big_file?(object, config)
    file?(object) && object.size >= config.multipart_size_threshold
  end

  # @param uuid [String]
  # @param file_name [String]
  # @return [Uploadcare::File]
  def self.create_basic_file(uuid:, file_name:, config:)
    Uploadcare::File.new(
      {
        uuid: uuid,
        original_filename: file_name
      },
      config
    )
  end
end
