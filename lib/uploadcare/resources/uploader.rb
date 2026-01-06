# frozen_string_literal: true

module Uploadcare
  # This serializer lets user upload files by various means, and usually returns an array of files
  # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload
  class Uploader < BaseResource
    def initialize(attributes = {}, config = Uploadcare.configuration)
      super
      @uploader_client = Uploadcare::UploaderClient.new(config)
    end

    # Upload file or group of files from array, File, or url
    #
    # @param object [Array], [String] or [File]
    # @param [Hash] options options for upload
    # @option options [Boolean] :store whether to store file on servers.
    def self.upload(object, options = {})
      if big_file?(object)
        multipart_upload(object, options)
      elsif file?(object)
        upload_file(object, options)
      elsif object.is_a?(Array)
        upload_files(object, options)
      elsif object.is_a?(String)
        upload_from_url(object, options)
      else
        raise ArgumentError, "Expected input to be a file/Array/URL, given: `#{object}`"
      end
    end

    # @param file [File]
    # @param [Hash] options options for upload
    # @option options [Boolean] :store whether to store file on servers.
    def self.upload_file(file, options = {})
      response = uploader_client.upload_many([file], options)
      file_name, uuid = response.first

      # Match v4.4.3 behavior exactly: check secret_key configuration
      if Uploadcare.configuration.secret_key.nil?
        # When no secret key: use file_info (upload API info endpoint)
        file_info = uploader_client.file_info(uuid)
        Uploadcare::File.new(file_info.merge(original_filename: file_name))
      else
        # When secret key is present: use File.info (REST API - more complete info)
        file = Uploadcare::File.new(uuid: uuid, original_filename: file_name)
        file.info
      end
    end

    # @param array_of_files [Array]
    # @param [Hash] options options for upload
    # @option options [Boolean] :store whether to store file on servers.
    def self.upload_files(array_of_files, options = {})
      response = uploader_client.upload_many(array_of_files, options)

      # For multiple file uploads, create basic file objects (exactly like v4.4.3)
      response.map do |file_name, uuid|
        create_basic_file(uuid, file_name)
      end
    end

    # check the status of the upload request.
    # @param url [String]
    # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload/operation/fromURLUploadStatus
    def self.get_upload_from_url_status(token)
      uploader_client.get_upload_from_url_status(token)
    end

    # upload file of size above 10mb (involves multipart upload)
    # @param file [File]
    # @param [Hash] options options for upload
    # @option options [Boolean] :store whether to store file on servers.
    def self.multipart_upload(file, options = {}, &)
      multipart_uploader_client = Uploadcare::MultipartUploaderClient.new(Uploadcare.configuration)
      response = multipart_uploader_client.upload(file, options, &)

      # Handle both current API response format and v4.4.3 Dry::Monads format
      if response.respond_to?(:success)
        # v4.4.3 style: Dry::Monads response
        Uploadcare::File.new(response.success)
      elsif response.is_a?(Hash) && response['uuid']
        # Current style: direct hash response
        Uploadcare::File.new(response)
      else
        response
      end
    end

    # upload files from url
    # @param url [String]
    # @param [Hash] options options for upload
    # @option options [Boolean] :store whether to store file on servers.
    def self.upload_from_url(url, options = {})
      response = uploader_client.upload_from_url(url, options)
      Uploadcare::File.new(response)
    end

    # Get information about an uploaded file (without the secret key)
    # @param uuid [String]
    def self.file_info(uuid)
      uploader_client.file_info(uuid)
    end

    def self.uploader_client
      @uploader_client ||= Uploadcare::UploaderClient.new
    end

    # @param object [File]
    # @return [Boolean]
    def self.file?(object)
      object.respond_to?(:path) && ::File.exist?(object.path)
    end

    # @param object [File]
    # @return [Boolean]
    def self.big_file?(object)
      file?(object) && object.size >= Uploadcare.configuration.multipart_size_threshold
    end

    # Create a basic File object with minimal data (exactly matches v4.4.3 behavior)
    # @param uuid [String]
    # @param file_name [String]
    # @return [Uploadcare::File]
    def self.create_basic_file(uuid, file_name)
      Uploadcare::File.new(
        uuid: uuid,
        original_filename: file_name
        # NOTE: v4.4.3 did NOT set original_file_url for multiple file uploads
      )
    end
  end
end
