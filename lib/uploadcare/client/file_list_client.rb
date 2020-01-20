# https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesList

module Uploadcare
  class FileListClient < ApiStruct::Client
    rest_api 'files'

    def file_list
      get(path: 'files/', headers: SimpleAuthenticationHeader.call)
    end
  end
end
