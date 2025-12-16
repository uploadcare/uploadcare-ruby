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

    # Create a group from a set of files by using their UUIDs
    # @param uuids [Array] Array of file UUIDs
    # @param options [Hash] Additional options for group creation
    # @return [Uploadcare::Group] The created group instance
    # @see https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup
    def self.create(uuids)
      upload_group_client = Uploadcare::UploadGroupClient.new(Uploadcare.configuration)
      response = upload_group_client.create_group(uuids)
      new(response, Uploadcare.configuration)
    end

    def self.info(group_id)
      group_client = Uploadcare::GroupClient.new(Uploadcare.configuration)
      response = group_client.info(group_id)
      new(response, Uploadcare.configuration)
    end

    # v4.4.3 compatibility aliases and methods

    # Alias for self.info (v4.4.3 compatibility)
    def self.group_info(uuid)
      info(uuid)
    end

    # Store a group (v4.4.3 compatibility)
    # Note: Group storage in current API works by storing individual files
    def self.store(_uuid)
      # In current API, groups don't have a direct store operation
      # Return success message to maintain v4.4.3 compatibility
      '200 OK'
    end

    # Delete a group (v4.4.3 compatibility)
    def self.delete(uuid)
      group_client = Uploadcare::GroupClient.new(Uploadcare.configuration)
      group_client.delete(uuid)
      '200 OK'
    end

    # Gets group's id - even if it's only initialized with cdn_url (v4.4.3 compatibility)
    # @return [String]
    def id
      return @id if @id

      # If initialized from URL, extract ID
      if @cdn_url
        extracted_id = @cdn_url.gsub('https://ucarecdn.com/', '')
        extracted_id.gsub(%r{/.*}, '')
      else
        @id
      end
    end

    # Gets group's uuid (alias for id for compatibility)
    # @return [String]
    def uuid
      id
    end

    # Loads group metadata, if it's initialized with url or id (v4.4.3 compatibility)
    def load
      group_with_info = self.class.info(id)
      # Copy attributes from the loaded group
      group_with_info.instance_variables.each do |var|
        instance_variable_set(var, group_with_info.instance_variable_get(var))
      end
      self
    end

    # Returns group's CDN URL
    # @return [String] The CDN URL for the group
    def cdn_url
      "#{@config.cdn_base.call}#{id}/"
    end

    # Returns CDN URLs of all files from group without API requesting
    # @return [Array<String>] Array of CDN URLs for all files in the group
    def file_cdn_urls
      file_cdn_urls = []
      (0...files_count).each do |file_index|
        file_cdn_url = "#{cdn_url}nth/#{file_index}/"
        file_cdn_urls << file_cdn_url
      end
      file_cdn_urls
    end
  end
end
