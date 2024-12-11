# frozen_string_literal: true

module Uploadcare
  class FileClient < RestClient
    # Gets list of files without pagination fields
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesList
    def list(params = {})
      get('files/', params)
    end

    # Stores a file by UUID
    # @param uuid [String] The UUID of the file to store
    # @return [Hash] The response body containing the file details
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesStore
    def store(uuid)
      put("/files/#{uuid}/storage/")
    end

    # Deletes a file by UUID
    # @param uuid [String] The UUID of the file to delete
    # @return [Hash] The response body containing the deleted file details
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/deleteFileStorage
    def delete(uuid)
      del("/files/#{uuid}/storage/")
    end

    # Get file information by its UUID (immutable).
    # @param uuid [String] The UUID of the file
    # @return [Hash] The response body containing the file details
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/fileInfo
    def info(uuid, params= {})
      get("/files/#{uuid}/", params)
    end

    # Batch store files by UUIDs
    # @param uuids [Array<String>] List of file UUIDs to store
    # @return [Hash] The response body containing 'result' and 'problems'
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesStoring
    def batch_store(uuids)
      put('/files/storage/', uuids)
    end

    # Batch delete files by UUIDs
    # @param uuids [Array<String>] List of file UUIDs to delete
    # @return [Hash] The response body containing 'result' and 'problems'
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesDelete
    def batch_delete(uuids)
      del('/files/storage/', uuids)
    end

    # Copies a file to local storage
    # @param source [String] The CDN URL or UUID of the file to copy
    # @param options [Hash] Optional parameters
    # @option options [String] :store ('false') Whether to store the copied file ('true' or 'false')
    # @option options [Hash] :metadata Arbitrary additional metadata
    # @return [Hash] The response body containing 'type' and 'result' fields
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/createLocalCopy
    def local_copy(source, options = {})
      params = { source: source }.merge(options)
      post('/files/local_copy/', params)
    end

    # Copies a file to remote storage
    # @param source [String] The CDN URL or UUID of the file to copy
    # @param target [String] The name of the custom storage
    # @param options [Hash] Optional parameters
    # @option options [Boolean] :make_public (true) Whether the copied file is public
    # @option options [String] :pattern ('${default}') Pattern for the file name in the custom storage
    # @return [Hash] The response body containing 'type' and 'result' fields
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/createRemoteCopy
    def remote_copy(source, target, options = {})
      params = { source: source, target: target }.merge(options)
      post('/files/remote_copy/', params)
    end
  end
end
