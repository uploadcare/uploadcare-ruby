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
      query = '?' + options.to_a.map { |x| "#{x[0]}=#{x[1]}" }.join('&') unless options.empty?
      signed_request(method: 'GET', uri: "/files/#{query}")
    end

    # Make a group of files "stored". This will prevent them from being deleted automatically
    # https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesStoring
    # uuids: Array

    def batch_store(uuids)
      body = uuids.to_json
      signed_request(method: 'PUT', uri: '/files/storage/', body: body)
    end

    # Delete several files by list of uids
    # https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesDelete
    # uuids: Array

    def batch_delete(uuids)
      body = uuids.to_json
      signed_request(method: 'DELETE', uri: '/files/storage/', body: body)
    end

    alias store batch_store
    alias delete batch_delete
    alias list file_list
  end
end
