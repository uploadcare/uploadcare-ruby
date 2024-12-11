# frozen_string_literal: true

module Uploadcare
  class Group < BaseResource
    ATTRIBUTES = %i[
      id datetime_removed datetime_stored datetime_uploaded is_image is_ready mime_type original_file_url cdn_url
      original_filename size url uuid variations content_info metadata appdata source datetime_created files_count files
    ].freeze

    attr_accessor(*ATTRIBUTES)

    def initialize(attributes = {}, config = Uploadcare.configuration)
      super
      @group_client = Uploadcare::GroupClient.new(config)
    end
    # Retrieves a paginated list of groups based on the provided parameters.
    # @param params [Hash] Optional parameters for filtering and pagination.
    # @param config [Uploadcare::Configuration] The Uploadcare configuration to use.
    # @return [Uploadcare::PaginatedCollection] A collection of groups with pagination details.
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/groupsList

    def self.list(params = {}, config = Uploadcare.configuration)
      group_client = Uploadcare::GroupClient.new(config)
      response = group_client.list(params)
      groups = response['results'].map { |data| new(data, config) }

      PaginatedCollection.new(
        resources: groups,
        next_page: response['next'],
        previous_page: response['previous'],
        per_page: response['per_page'],
        total: response['total'],
        client: group_client,
        resource_class: self
      )
    end

    # Retrieves information about a specific group by UUID.
    # @param uuid [String] The UUID of the group to retrieve.
    # @return [Uploadcare::Group] The updated instance with group information.
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/groupInfo
    # TODO - Remove uuid if the opeartion is being perfomed on same file

    def info(uuid)
      response = @group_client.info(uuid)

      assign_attributes(response)
      self
    end
    # Deletes a group by UUID.
    # @param uuid [String] The UUID of the group to delete.
    # @return [Nil] Returns nil on successful deletion.
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/deleteGroup
    # TODO - Remove uuid if the opeartion is being perfomed on same file

    def delete(uuid)
      @group_client.delete(uuid)
    end
  end
end
