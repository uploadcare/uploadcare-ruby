# frozen_string_literal: true

module Uploadcare
  # API client for handling file lists
  class FileListClient < ApiStruct::Client
    rest_api 'files'

    # Returns a pagination json of files stored in project
    # https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesList
    #
    # valid options:
    # removed: [true|false]
    # stored: [true|false]
    # limit: (1..1000)
    # ordering: ["datetime_uploaded"|"-datetime_uploaded"|"size"|"-size"]
    # from: number of files skipped

    def file_list(**options)
      query = ''
      query = '?' + options.to_a.map { |x| "#{x[0]}=#{x[1]}" }.join("&") unless options.empty?
      headers = AuthenticationHeader.call(method: 'GET', uri: "/files/#{query}")
      get(path: 'files/', headers: headers, params: options)
    end
    alias list file_list

    # Store multiple files, preventing them from being deleted in 2 weeks
    # https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesStoring

    def batch_store(uuids)
      result = put(path: 'files/storage/', headers: SimpleAuthenticationHeader.call, body: uuids.to_json)
      result.success[:files] = result.success[:result]
      result
    end

    alias _delete delete

    # Delete multiple files
    # https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesDelete

    def batch_delete(uuids)
      result = _delete(path: 'files/storage/', headers: SimpleAuthenticationHeader.call, body: uuids.to_json)
      result.success[:files] = result.success[:result]
      result
    end
  end
end
