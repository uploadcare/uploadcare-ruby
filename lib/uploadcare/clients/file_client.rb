# frozen_string_literal: true

# Client for file operations in the REST API.
class Uploadcare::FileClient < Uploadcare::RestClient
  # Gets list of files without pagination fields
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesList
  def list(params: {}, request_options: {})
    get(path: 'files/', params: params, headers: {}, request_options: request_options)
  end

  # Stores a file by UUID
  # @param uuid [String] The UUID of the file to store
  # @return [Hash] The response body containing the file details
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesStore
  def store(uuid:, request_options: {})
    put(path: "/files/#{uuid}/storage/", params: {}, headers: {}, request_options: request_options)
  end

  # Deletes a file by UUID
  # @param uuid [String] The UUID of the file to delete
  # @return [Hash] The response body containing the deleted file details
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/deleteFileStorage
  def delete(uuid:, request_options: {})
    super(path: "/files/#{uuid}/storage/", params: {}, headers: {}, request_options: request_options)
  end

  # Get file information by its UUID (immutable).
  # @param uuid [String] The UUID of the file
  # @return [Hash] The response body containing the file details
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/fileInfo
  def info(uuid:, params: {}, request_options: {})
    get(path: "/files/#{uuid}/", params: params, headers: {}, request_options: request_options)
  end

  # Batch store files by UUIDs
  # @param uuids [Array<String>] List of file UUIDs to store
  # @return [Hash] The response body containing 'result' and 'problems'
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesStoring
  def batch_store(uuids:, request_options: {})
    put(path: '/files/storage/', params: uuids, headers: {}, request_options: request_options)
  end

  # Batch delete files by UUIDs
  # @param uuids [Array<String>] List of file UUIDs to delete
  # @return [Hash] The response body containing 'result' and 'problems'
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/filesDelete
  def batch_delete(uuids:, request_options: {})
    request(method: :delete, path: '/files/storage/', params: uuids, headers: {}, request_options: request_options)
  end

  # Copies a file to local storage
  # @param source [String] The CDN URL or UUID of the file to copy
  # @param options [Hash] Optional parameters
  # @option options [String] :store ('false') Whether to store the copied file ('true' or 'false')
  # @option options [Hash] :metadata Arbitrary additional metadata
  # @return [Hash] The response body containing 'type' and 'result' fields
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/createLocalCopy
  def local_copy(source:, options: {}, request_options: {})
    params = { source: source }.merge(options)
    post(path: '/files/local_copy/', params: params, headers: {}, request_options: request_options)
  end

  # Copies a file to remote storage
  # @param source [String] The CDN URL or UUID of the file to copy
  # @param target [String] The name of the custom storage
  # @param options [Hash] Optional parameters
  # @option options [Boolean] :make_public (true) Whether the copied file is public
  # @option options [String] :pattern ('${default}') Pattern for the file name in the custom storage
  # @return [Hash] The response body containing 'type' and 'result' fields
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/createRemoteCopy
  def remote_copy(source:, target:, options: {}, request_options: {})
    params = { source: source, target: target }.merge(options)
    post(path: '/files/remote_copy/', params: params, headers: {}, request_options: request_options)
  end
end
