# frozen_string_literal: true

module Uploadcare
  # API client for handling file lists
  class FileListClient < RestClient

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
      signed_request(method: 'GET', uri: "/files/#{query}")
    end
    alias list file_list

    # Store multiple files, preventing them from being deleted in 2 weeks
    # https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesStoring

    def batch_store(uuids)
      body = uuids.to_json
      signed_request(method: 'PUT', uri: '/files/storage/', content: body)
    end

    alias _delete delete

    # Delete multiple files
    # https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesDelete

    def batch_delete(uuids)
      body = uuids.to_json
      signed_request(method: 'DELETE', uri: '/files/storage/', content: body)
    end
  end
end
