# frozen_string_literal: true

require_relative 'rest_client'

module Uploadcare
  module Client
    # API client for handling single files
    # @see https://uploadcare.com/docs/api_reference/rest/accessing_files/
    # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#tag/File
    class FileClient < RestClient
      # Gets list of files without pagination fields

      def index
        response = get(uri: '/files/')
        response.fmap { |i| i[:results] }
      end

      # Acquire file info
      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/fileInfo

      def info(uuid)
        get(uri: "/files/#{uuid}/")
      end
      alias :file :info

      # 'copy' method is used to copy original files or their modified versions to default storage.
      # Source files MAY either be stored or just uploaded and MUST NOT be deleted.
      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/copyFile

      def copy(**options)
        body = options.compact.to_json
        post(uri: '/files/', content: body)
      end

      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/deleteFile

      def delete(uuid)
        request(method: 'DELETE', uri: "/files/#{uuid}/")
      end

      # Store a single file, preventing it from being deleted in 2 weeks
      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/storeFile

      def store(uuid)
        put(uri: "/files/#{uuid}/storage/")
      end
    end
  end
end
