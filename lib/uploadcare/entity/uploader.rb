# frozen_string_literal: true

module Uploadcare
  module Entity
    # This serializer lets user upload files by various means, and usually returns an array of files
    # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload
    class Uploader < Entity
      client_service UploaderClient
      client_service MultipartUploaderClient, only: :upload, prefix: :multipart

      attr_entity :files
      has_entities :files, as: Uploadcare::Entity::File

      # Upload file or group of files from array, File, or url
      #
      # @param object [Array], [String] or [File]
      # @param [Hash] options options for upload
      # @option options [Boolean] :store (false) whether to store file on servers.
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

      # upload single file
      def self.upload_file(file, options = {})
        response = UploaderClient.new.upload_many([file], options)
        uuid = response.success.values.first
        if Uploadcare.config.secret_key.nil?
          Uploadcare::Entity::File.new(file_info(uuid).success)
        else
          # we can get more info about the uploaded file
          Uploadcare::Entity::File.info(uuid)
        end
      end

      # upload multiple files
      def self.upload_files(arr, options = {})
        response = UploaderClient.new.upload_many(arr, options)
        response.success.map { |pair| Uploadcare::Entity::File.new(uuid: pair[1], original_filename: pair[0]) }
      end

      # upload file of size above 10mb (involves multipart upload)
      def self.multipart_upload(file, options = {}, &block)
        response = MultipartUploaderClient.new.upload(file, options, &block)
        Uploadcare::Entity::File.new(response.success)
      end

      # upload files from url
      # @param url [String]
      def self.upload_from_url(url, options = {})
        response = UploaderClient.new.upload_from_url(url, options)
        return response.success[:token] unless response.success[:files]

        response.success[:files].map { |file_data| Uploadcare::Entity::File.new(file_data) }
      end

      # gets a status of upload from url
      # @param url [String]
      def self.get_upload_from_url_status(token)
        UploaderClient.new.get_upload_from_url_status(token)
      end

      # Get information about an uploaded file (without the secret key)
      # @param uuid [String]
      def self.file_info(uuid)
        UploaderClient.new.file_info(uuid)
      end

      class << self
        private

        # check if object is a file
        def file?(object)
          object.respond_to?(:path) && ::File.exist?(object.path)
        end

        # check if object needs to be uploaded using multipart upload
        def big_file?(object)
          file?(object) && object.size >= Uploadcare.config.multipart_size_threshold
        end
      end
    end
  end
end
