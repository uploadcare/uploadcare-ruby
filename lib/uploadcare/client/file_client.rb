# frozen_string_literal: true

module Uploadcare
  # API client for handling single files
  # https://uploadcare.com/docs/api_reference/rest/accessing_files/
  # https://uploadcare.com/api-refs/rest-api/v0.5.0/#tag/File
  class FileClient < ApiStruct::Client
    rest_api 'files'

    # Acquire file info
    # https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/fileInfo

    def info(uuid)
      get(path: "files/#{uuid}/", headers: SimpleAuthenticationHeader.call)
    end

    # 'copy' method is used to copy original files or their modified versions to default storage.
    # Source files MAY either be stored or just uploaded and MUST NOT be deleted.
    # https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/copyFile

    def copy(**options)
      post(path: 'files/', headers: SimpleAuthenticationHeader.call, body: options.to_json)
    end

    alias _delete delete

    # https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/deleteFile

    def delete(uuid)
      _delete(path: "files/#{uuid}/", headers: SimpleAuthenticationHeader.call)
    end

    # Store a single file, preventing it from being deleted in 2 weeks
    # https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/storeFile

    def store(uuid)
      put(path: "files/#{uuid}/storage/", headers: SimpleAuthenticationHeader.call)
    end
  end
end
