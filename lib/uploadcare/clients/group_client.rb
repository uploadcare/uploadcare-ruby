# frozen_string_literal: true

module Uploadcare
  class GroupClient < RestClient
    # Fetches a paginated list of groups
    # @param params [Hash] Optional query parameters for filtering, limit, ordering, etc.
    # @return [Hash] The response containing the list of groups
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/groupsList
    def list(params = {})
      get('/groups/', params)
    end

    # Fetches group information by its UUID
    # @param uuid [String] The UUID of the group (formatted as UUID~size)
    # @return [Hash] The response containing the group's details
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/groupInfo
    def info(uuid)
      get("/groups/#{uuid}/")
    end

    # Deletes a group by its UUID
    # @param uuid [String] The UUID of the group (formatted as UUID~size)
    # @return [NilClass] Returns nil on successful deletion
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/deleteGroup
    def delete(uuid)
      del("/groups/#{uuid}/")
    end
  end
end
