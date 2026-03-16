# frozen_string_literal: true

# REST API endpoint for file operations.
#
# Provides methods for listing, retrieving, storing, deleting, and copying files.
#
# @example
#   rest = Uploadcare::Api::Rest.new(config: config)
#   rest.files.list(params: { limit: 10 })
#   rest.files.info(uuid: "file-uuid")
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File
module Uploadcare
  module Api
    class Rest
      class Files
        # @return [Uploadcare::Api::Rest] Parent REST client
        attr_reader :rest

        # @param rest [Uploadcare::Api::Rest] Parent REST client
        def initialize(rest:)
          @rest = rest
        end

        # List files with optional filtering and pagination.
        #
        # @param params [Hash] Query parameters (limit, ordering, etc.)
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Paginated file list
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesList
        def list(params: {}, request_options: {})
          rest.get(path: '/files/', params: params, headers: {}, request_options: request_options)
        end

        # Get file information by UUID.
        #
        # @param uuid [String] The file UUID
        # @param params [Hash] Optional parameters (e.g., include: "appdata")
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] File details
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/fileInfo
        def info(uuid:, params: {}, request_options: {})
          rest.get(path: "/files/#{uuid}/", params: params, headers: {}, request_options: request_options)
        end

        # Store a file by UUID, making it permanently available.
        #
        # @param uuid [String] The file UUID
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Updated file details
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesStore
        def store(uuid:, request_options: {})
          rest.put(path: "/files/#{uuid}/storage/", params: {}, headers: {}, request_options: request_options)
        end

        # Delete a file by UUID.
        #
        # @param uuid [String] The file UUID
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Deleted file details
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/deleteFileStorage
        def delete(uuid:, request_options: {})
          rest.request(method: :delete, path: "/files/#{uuid}/storage/", params: {}, headers: {},
                       request_options: request_options)
        end

        # Batch store files by UUIDs.
        #
        # @param uuids [Array<String>] List of file UUIDs to store
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Hash with 'result' and 'problems' keys
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesStoring
        def batch_store(uuids:, request_options: {})
          rest.put(path: '/files/storage/', params: uuids, headers: {}, request_options: request_options)
        end

        # Batch delete files by UUIDs.
        #
        # @param uuids [Array<String>] List of file UUIDs to delete
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Hash with 'result' and 'problems' keys
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesDelete
        def batch_delete(uuids:, request_options: {})
          rest.request(method: :delete, path: '/files/storage/', params: uuids, headers: {},
                       request_options: request_options)
        end

        # Copy a file to local storage.
        #
        # @param source [String] CDN URL or UUID of the file to copy
        # @param options [Hash] Optional parameters (:store, :metadata)
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Hash with 'type' and 'result' keys
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/createLocalCopy
        def local_copy(source:, options: {}, request_options: {})
          params = { source: source }.merge(options)
          rest.post(path: '/files/local_copy/', params: params, headers: {}, request_options: request_options)
        end

        # Copy a file to remote storage.
        #
        # @param source [String] CDN URL or UUID of the file to copy
        # @param target [String] Name of the custom storage
        # @param options [Hash] Optional parameters (:make_public, :pattern)
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Hash with 'type' and 'result' keys
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/createRemoteCopy
        def remote_copy(source:, target:, options: {}, request_options: {})
          params = { source: source, target: target }.merge(options)
          rest.post(path: '/files/remote_copy/', params: params, headers: {}, request_options: request_options)
        end
      end
    end
  end
end
