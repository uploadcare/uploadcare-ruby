# frozen_string_literal: true

require_relative 'rest_client'

module Uploadcare
  module Client
    # API client for handling single files
    # @see https://uploadcare.com/docs/api_reference/rest/accessing_files/
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File
    class FileClient < RestClient
      # Gets list of files without pagination fields
      def index
        response = get(uri: '/files/')
        response.fmap { |i| i[:results] }
      end

      # Acquire file info
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/fileInfo
      def info(uuid, params = {})
        get(uri: "/files/#{uuid}/", params: params)
      end
      alias file info

      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/createLocalCopy
      def local_copy(options = {})
        body = options.compact.to_json
        post(uri: '/files/local_copy/', content: body)
      end

      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/createRemoteCopy
      def remote_copy(options = {})
        body = options.compact.to_json
        post(uri: '/files/remote_copy/', content: body)
      end

      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/deleteFileStorage
      def delete(uuid)
        request(method: 'DELETE', uri: "/files/#{uuid}/storage/")
      end

      # Store a single file, preventing it from being deleted in 2 weeks
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/storeFile
      def store(uuid)
        put(uri: "/files/#{uuid}/storage/")
      end
    end
  end
end
