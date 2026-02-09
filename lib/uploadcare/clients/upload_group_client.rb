# frozen_string_literal: true

# Groups serve a purpose of better organizing files in your Uploadcare projects.
# You can create one from a set of files by using their UUIDs.
# @see https://uploadcare.com/docs/api_reference/upload/groups/
class Uploadcare::UploadGroupClient < Uploadcare::UploadClient
  # Create a group from a set of files by using their UUIDs
  # @param uuids [Array] Array of file UUIDs or file objects
  # @param options [Hash] Additional options for group creation
  # @return [Hash] The response containing group information
  # @see https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup
  def create_group(uuids:, request_options: {}, **options)
    body_hash = group_body_hash(uuids, options)
    post(path: 'group/', params: body_hash, headers: {}, request_options: request_options)
  end

  # Get group info
  # @param group_id [String] The group ID to retrieve information for
  # @return [Hash] The response containing group information
  # @see https://uploadcare.com/api-refs/upload-api/#operation/filesGroupInfo
  def info(group_id:, request_options: {})
    get(path: 'group/info/', params: { pub_key: config.public_key, group_id: group_id }, headers: {},
        request_options: request_options)
  end

  private

  # Builds the body hash for group creation using multipart form format
  # @param uuids [Array] Array of file UUIDs or file objects
  # @param options [Hash] Additional options for group creation
  # @return [Hash] The request body parameters formatted for multipart
  def group_body_hash(uuids, options = {})
    parsed_files = parse_uuids(uuids)

    # Start with the public key
    params = { 'pub_key' => config.public_key }

    # Add each file with indexed parameter names (files[0], files[1], etc.)
    params.merge!(file_params(parsed_files))

    # Add signature and expire if provided
    params['signature'] = options['signature'] || options[:signature] if options['signature'] || options[:signature]
    params['expire'] = options['expire'] || options[:expire] if options['expire'] || options[:expire]

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
