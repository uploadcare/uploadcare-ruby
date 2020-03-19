# frozen_string_literal: true

require_relative 'upload_client'

module Uploadcare
  module Client
    # Groups serve a purpose of better organizing files in your Uploadcare projects.
    # You can create one from a set of files by using their UUIDs.
    # @see https://uploadcare.com/docs/api_reference/upload/groups/
    class GroupClient < UploadClient
      # Create files group from a set of files by using their UUIDs.
      # @see https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup
      def create(file_list, **options)
        body_hash = group_body_hash(file_list, **options)
        body = HTTP::FormData::Multipart.new(body_hash)
        post(path: 'group/',
             headers: { 'Content-type': body.content_type },
             body: body)
      end

      # Get group info
      # @see https://uploadcare.com/api-refs/upload-api/#operation/filesGroupInfo
      def info(group_id)
        get(path: 'group/info/', params: { 'pub_key': Uploadcare.config.public_key, 'group_id': group_id })
      end

      private

      def file_params(file_ids)
        ids = (0...file_ids.size).map { |i| "files[#{i}]" }
        ids.zip(file_ids).to_h
      end

      def group_body_hash(file_list, **options)
        { pub_key: Uploadcare.config.public_key }.merge(file_params(parse_file_list(file_list))).merge(**options)
      end

      # API accepts only list of ids, but some users may want to upload list of files
      # @return [Array] of [String]
      def parse_file_list(file_list)
        file_list.map { |file| file.methods.include?(:uuid) ? file.uuid : file }
      end
    end
  end
end
