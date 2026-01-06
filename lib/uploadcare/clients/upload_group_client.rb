# frozen_string_literal: true

module Uploadcare
  # Groups serve a purpose of better organizing files in your Uploadcare projects.
  # You can create one from a set of files by using their UUIDs.
  # @see https://uploadcare.com/docs/api_reference/upload/groups/
  class UploadGroupClient < UploadClient
    # Create a group from a set of files by using their UUIDs
    # @param uuids [Array] Array of file UUIDs or file objects
    # @param options [Hash] Additional options for group creation
    # @return [Hash] The response containing group information
    # @see https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup
    def create_group(uuids, options = {})
      body_hash = group_body_hash(uuids, options)
      post('group/', body_hash)
    end

    # Get group info
    # @param group_id [String] The group ID to retrieve information for
    # @return [Hash] The response containing group information
    # @see https://uploadcare.com/api-refs/upload-api/#operation/filesGroupInfo
    def info(group_id)
      get('group/info/', { pub_key: Uploadcare.configuration.public_key, group_id: group_id })
    end

    private

    # Builds the body hash for group creation using multipart form format
    # @param uuids [Array] Array of file UUIDs or file objects
    # @param options [Hash] Additional options for group creation
    # @return [Hash] The request body parameters formatted for multipart
    def group_body_hash(uuids, _options = {})
      parsed_files = parse_uuids(uuids)

      # Start with the public key
      params = { 'pub_key' => Uploadcare.configuration.public_key }

      # Add each file with indexed parameter names (files[0], files[1], etc.)
      params.merge!(file_params(parsed_files))

      params
    end

    # Convert file IDs to parameter format for API (files[0], files[1], etc.)
    # @param file_ids [Array] Array of file IDs
    # @return [Hash] Hash with indexed file parameters
    def file_params(file_ids)
      result = {}
      file_ids.each_with_index do |file_id, index|
        result["files[#{index}]"] = file_id
      end
      result
    end

    # API accepts only list of ids, but some users may want to upload list of files
    # @param uuids [Array] Array of file UUIDs or file objects
    # @return [Array] Array of file UUID strings
    def parse_uuids(uuids)
      uuids.map { |file| file.methods.include?(:uuid) ? file.uuid : file }
    end
  end
end
