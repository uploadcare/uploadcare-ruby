# frozen_string_literal: true

# https://uploadcare.com/docs/api_reference/rest/accessing_files/
# https://uploadcare.com/api-refs/rest-api/v0.5.0/#tag/File

module Uploadcare
  class FileClient < ApiStruct::Client
    rest_api 'files'

    def info(uuid)
      response = get(path: "files/#{uuid}/", headers: SimpleAuthenticationHeader.call)
    end

    def copy(**options)
      post(path: 'files/', headers: SimpleAuthenticationHeader.call, body: options.to_json)
    end

    alias :_delete :delete
    def delete(uuid)
      _delete(path: "files/#{uuid}/", headers: SimpleAuthenticationHeader.call)
    end

    def store(uuid)
      put(path: "files/#{uuid}/storage/", headers: SimpleAuthenticationHeader.call)
    end
  end
end
