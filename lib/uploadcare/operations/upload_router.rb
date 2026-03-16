# frozen_string_literal: true

# Routes upload requests to the appropriate Upload API endpoint.
#
# Handles the decision logic for choosing between:
# - Direct upload (small files < multipart threshold)
# - Multipart upload (large files >= multipart threshold)
# - URL upload (string URLs)
# - Batch upload (arrays of files)
#
# @example
#   router = Uploadcare::Operations::UploadRouter.new(client: client)
#   file = router.upload(File.open("image.jpg"))
#   file = router.upload("https://example.com/image.jpg")
#   files = router.upload([file1, file2])
module Uploadcare
  module Operations
    class UploadRouter
      # @return [Uploadcare::Client] Client instance
      attr_reader :client

      # @param client [Uploadcare::Client] Client instance
      def initialize(client:)
        @client = client
      end

      # Upload a file, URL, or array of files.
      #
      # Automatically routes to the appropriate upload method based on the source type:
      # - File/IO objects >= multipart threshold → multipart upload
      # - File/IO objects < multipart threshold → direct upload
      # - Arrays → batch direct upload
      # - Strings → URL upload
      #
      # @param source [File, IO, String, Array] Upload source
      # @param options [Hash] Upload options (:store, :metadata, etc.)
      # @param request_options [Hash] Request options
      # @return [Uploadcare::Resources::File, Array<Uploadcare::Resources::File>, Hash]
      # @raise [ArgumentError] if source type is not recognized
      def upload(source, request_options: {}, **options, &block)
        if big_file?(source)
          multipart_upload(file: source, request_options: request_options, **options, &block)
        elsif file?(source)
          upload_file(file: source, request_options: request_options, **options)
        elsif source.is_a?(Array)
          upload_files(files: source, request_options: request_options, **options)
        elsif source.is_a?(String)
          upload_from_url(url: source, request_options: request_options, **options)
        else
          raise ArgumentError, "Expected input to be a File/Array/URL, given: `#{source}`"
        end
      end

      # Upload a single file directly.
      #
      # @param file [File, IO] File to upload
      # @param options [Hash] Upload options
      # @param request_options [Hash] Request options
      # @return [Uploadcare::Resources::File]
      def upload_file(file:, request_options: {}, **options)
        response = Uploadcare::Result.unwrap(
          client.api.upload.files.direct_many(files: [file], request_options: request_options, **options)
        )
        file_name, uuid = response.first
        Uploadcare::Resources::File.new({ uuid: uuid, original_filename: file_name }, client)
      end

      # Upload multiple files directly.
      #
      # @param files [Array<File, IO>] Files to upload
      # @param options [Hash] Upload options
      # @param request_options [Hash] Request options
      # @return [Array<Uploadcare::Resources::File>]
      def upload_files(files:, request_options: {}, **options)
        response = Uploadcare::Result.unwrap(
          client.api.upload.files.direct_many(files: files, request_options: request_options, **options)
        )
        response.map do |file_name, uuid|
          Uploadcare::Resources::File.new({ uuid: uuid, original_filename: file_name }, client)
        end
      end

      # Upload a file from URL.
      #
      # @param url [String] Source URL
      # @param options [Hash] Upload options (:async, :store, :metadata)
      # @param request_options [Hash] Request options
      # @return [Uploadcare::Resources::File, Hash] File resource (sync) or token hash (async)
      def upload_from_url(url:, request_options: {}, **options)
        response = Uploadcare::Result.unwrap(
          client.api.upload.files.from_url(source_url: url, request_options: request_options, **options)
        )
        return response if options[:async]

        Uploadcare::Resources::File.new(response, client)
      end

      # Upload a large file using multipart upload.
      #
      # @param file [File, IO] Large file to upload
      # @param options [Hash] Upload options
      # @param request_options [Hash] Request options
      # @return [Uploadcare::Resources::File]
      def multipart_upload(file:, request_options: {}, **options, &block)
        response = Uploadcare::Result.unwrap(
          Uploadcare::Operations::MultipartUpload.new(
            upload_client: client.api.upload,
            config: client.config
          ).upload(file: file, request_options: request_options, **options, &block)
        )
        return response unless response.is_a?(Hash) && response['uuid']

        Uploadcare::Resources::File.new(response, client)
      end

      # Get upload-from-URL status.
      #
      # @param token [String] Upload token
      # @param request_options [Hash] Request options
      # @return [Hash] Status response
      def upload_from_url_status(token:, request_options: {})
        Uploadcare::Result.unwrap(
          client.api.upload.files.from_url_status(token: token, request_options: request_options)
        )
      end

      # Get file info from Upload API (without secret key).
      #
      # @param file_id [String] File UUID
      # @param request_options [Hash] Request options
      # @return [Hash] File information
      def file_info(file_id:, request_options: {})
        Uploadcare::Result.unwrap(
          client.api.upload.files.info(file_id: file_id, request_options: request_options)
        )
      end

      private

      def file?(object)
        !object.is_a?(String) && object.respond_to?(:read)
      end

      def big_file?(object)
        return false unless file?(object)

        upload_size(object) >= client.config.multipart_size_threshold
      rescue StandardError
        false
      end

      def upload_size(object)
        return object.size if object.respond_to?(:size)
        return ::File.size(object.path) if object.respond_to?(:path) && object.path && ::File.exist?(object.path)

        0
      end
    end
  end
end
