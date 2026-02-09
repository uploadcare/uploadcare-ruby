# frozen_string_literal: true

require 'uri'

# Client for group operations in the REST API.
class Uploadcare::GroupClient < Uploadcare::RestClient
  # Fetches a paginated list of groups
  # @param params [Hash] Optional query parameters for filtering, limit, ordering, etc.
  # @return [Hash] The response containing the list of groups
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/groupsList
  def list(params: {}, request_options: {})
    get(path: '/groups/', params: params, headers: {}, request_options: request_options)
  end

  # Fetches group information by its UUID
  # @param uuid [String] The UUID of the group (formatted as UUID~size)
  # @return [Hash] The response containing the group's details
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/groupInfo
  def info(uuid:, request_options: {})
    encoded_uuid = URI.encode_www_form_component(uuid)
    get(path: "/groups/#{encoded_uuid}/", params: {}, headers: {}, request_options: request_options)
  end

  # Deletes a group by its UUID
  # @param uuid [String] The UUID of the group (formatted as UUID~size)
  # @return [NilClass] Returns nil on successful deletion
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/deleteGroup
  def delete(uuid:, request_options: {})
    encoded_uuid = URI.encode_www_form_component(uuid)
    super(path: "/groups/#{encoded_uuid}/", params: {}, headers: {}, request_options: request_options)
  end
end
