# frozen_string_literal: true

module Uploadcare
  module Client
    # API client for handling file lists
    class FileListClient < RestClient
      # Returns a pagination json of files stored in project
      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesList
      #
      # valid options:
      # removed: [true|false]
      # stored: [true|false]
      # limit: (1..1000)
      # ordering: ["datetime_uploaded"|"-datetime_uploaded"|"size"|"-size"]
      # from: number of files skipped

      def file_list(**options)
        query = options.empty? ? '' : '?' + URI.encode_www_form(options)
        get(uri: "/files/#{query}")
      end

      # Make a set of files "stored". This will prevent them from being deleted automatically
      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesStoring
      # uuids: Array

      def batch_store(uuids)
        body = uuids.to_json
        put(uri: '/files/storage/', body: body)
      end

      alias request_delete delete

      # Delete several files by list of uids
      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesDelete
      # uuids: Array

      def batch_delete(uuids)
        body = uuids.to_json
        request_delete(uri: '/files/storage/', body: body)
      end

      alias store_files batch_store
      alias delete_files batch_delete
      alias list file_list
    end
  end
end
