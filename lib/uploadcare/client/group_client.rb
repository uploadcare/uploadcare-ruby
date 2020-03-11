# frozen_string_literal: true

# frozen_string_literal true

module Uploadcare
  module Client
    # Groups serve a purpose of better organizing files in your Uploadcare projects.
    # You can create one from a set of files by using their UUIDs.
    # @see https://uploadcare.com/docs/api_reference/upload/groups/
    class GroupClient < ApiStruct::Client
      upload_api
      include Concerns::ErrorHandler

      # Create files group from a set of files by using their UUIDs.
      # @see https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup

      def create(file_list, **options)
        body_hash = {
          pub_key: Uploadcare.configuration.public_key
        }.merge(file_params(file_list), options)
        body = HTTP::FormData::Multipart.new(body_hash)
        post(path: 'group/',
             headers: { 'Content-type': body.content_type },
             body: body)
      end

      # Get group info
      # @see https://uploadcare.com/api-refs/upload-api/#operation/filesGroupInfo

      def info(group_id)
        get(path: 'group/info/', params: { 'pub_key': Uploadcare.configuration.public_key, 'group_id': group_id })
      end

      private

      def file_params(file_ids)
        ids = (0...file_ids.size).map { |i| "files[#{i}]" }
        ids.zip(file_ids).to_h
      end
    end
  end
end
