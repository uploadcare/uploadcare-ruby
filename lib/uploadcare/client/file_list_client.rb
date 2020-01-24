# frozen_string_literal: true

# https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesList

module Uploadcare
  class FileListClient < ApiStruct::Client
    rest_api 'files'

    def file_list(**options)
      get(path: 'files/', headers: SimpleAuthenticationHeader.call, params: options)
    end
    alias :list :file_list

    def batch_store(uuids)
      result = put(path: "files/storage/", headers: SimpleAuthenticationHeader.call, body: uuids.to_json)
      result.success[:files] = result.success[:result]
      result
    end

    alias :_delete :delete
    def batch_delete(uuids)
      result = _delete(path: "files/storage/", headers: SimpleAuthenticationHeader.call, body: uuids.to_json)
      result.success[:files] = result.success[:result]
      result
    end
  end
end
