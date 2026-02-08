# frozen_string_literal: true

module Uploadcare
  # This serializer lets user upload files by various means, and usually returns an array of files
  # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload
  class Uploader < BaseResource
    def initialize(attributes = {}, config = Uploadcare.configuration)
      super
      @uploader_client = Uploadcare::UploaderClient.new(config: config)
    end

    # Upload file or group of files from array, File, or url
    #
    # @param object [Array], [String] or [File]
    # @param [Hash] options options for upload
    # @option options [Boolean] :store whether to store file on servers.
    def self.upload(object:, config: Uploadcare.configuration, **, &)
      if big_file?(object, config)
        multipart_upload(file: object, config: config, **, &)
      elsif file?(object)
        upload_file(file: object, config: config, **)
      elsif object.is_a?(Array)
        upload_files(files: object, config: config, **)
      elsif object.is_a?(String)
        upload_from_url(url: object, config: config, **)
      else
        raise ArgumentError, "Expected input to be a file/Array/URL, given: `#{object}`"
      end
    end

    # @param file [File]
    # @param [Hash] options options for upload
    # @option options [Boolean] :store whether to store file on servers.
    def self.upload_file(file:, config: Uploadcare.configuration, **)
      response = Uploadcare::Result.unwrap(uploader_client(config: config).upload_many(files: [file], **))
      file_name, uuid = response.first

      Uploadcare::File.new({ uuid: uuid, original_filename: file_name }, config)
    end

    # @param array_of_files [Array]
    # @param [Hash] options options for upload
    # @option options [Boolean] :store whether to store file on servers.
    def self.upload_files(files:, config: Uploadcare.configuration, **)
      response = Uploadcare::Result.unwrap(uploader_client(config: config).upload_many(files: files, **))

      response.map do |file_name, uuid|
        create_basic_file(uuid: uuid, file_name: file_name, config: config)
      end
    end

    # check the status of the upload request.
    # @param url [String]
    # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload/operation/fromURLUploadStatus
    def self.get_upload_from_url_status(token:, config: Uploadcare.configuration, request_options: {})
      upload_from_url_status(token: token, config: config, request_options: request_options)
    end

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
    # @param [Hash] options options for upload
    # @option options [Boolean] :store whether to store file on servers.
    def self.multipart_upload(file:, config: Uploadcare.configuration, request_options: {}, **, &)
      multipart_uploader_client = Uploadcare::MultipartUploaderClient.new(config: config)
      response = Uploadcare::Result.unwrap(multipart_uploader_client.upload(file: file,
                                                                            request_options: request_options,
                                                                            **, &))
      return response unless response.is_a?(Hash) && response['uuid']

      Uploadcare::File.new(response, config)
    end

    # upload files from url
    # @param url [String]
    # @param [Hash] options options for upload
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

    # Get information about an uploaded file (without the secret key)
    # @param uuid [String]
    def self.file_info(uuid:, config: Uploadcare.configuration, request_options: {})
      Uploadcare::Result.unwrap(uploader_client(config: config).file_info(uuid: uuid, request_options: request_options))
    end

    def self.uploader_client(config: Uploadcare.configuration)
      Uploadcare::UploaderClient.new(config: config)
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
end
