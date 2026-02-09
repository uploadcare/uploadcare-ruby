# frozen_string_literal: true

require 'uri'

# Group resource.
class Uploadcare::Group < Uploadcare::BaseResource
  # Group attributes exposed by the API.
  ATTRIBUTES = %i[
    id datetime_removed datetime_stored datetime_uploaded is_image is_ready mime_type original_file_url cdn_url
    original_filename size url uuid variations content_info metadata appdata source datetime_created files_count files
  ].freeze

  attr_accessor(*ATTRIBUTES)

  def initialize(attributes = {}, config = Uploadcare.configuration)
    super
    @group_client = Uploadcare::GroupClient.new(config: config)
  end
  # Retrieves a paginated list of groups based on the provided parameters.
  # @param params [Hash] Optional parameters for filtering and pagination.
  # @param config [Uploadcare::Configuration] The Uploadcare configuration to use.
  # @return [Uploadcare::PaginatedCollection] A collection of groups with pagination details.
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/groupsList

  def self.list(params: {}, config: Uploadcare.configuration, request_options: {})
    group_client = Uploadcare::GroupClient.new(config: config)
    response = Uploadcare::Result.unwrap(group_client.list(params: params, request_options: request_options))
    groups = response['results'].map { |data| new(data, config) }

    Uploadcare::PaginatedCollection.new(
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
  def info(uuid: nil, request_options: {})
    response = Uploadcare::Result.unwrap(@group_client.info(uuid: uuid || id, request_options: request_options))

    assign_attributes(response)
    self
  end

  # Deletes a group by UUID.
  # @param uuid [String] The UUID of the group to delete.
  # @return [Nil] Returns nil on successful deletion.
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/deleteGroup
  def delete(uuid: nil, request_options: {})
    Uploadcare::Result.unwrap(@group_client.delete(uuid: uuid || id, request_options: request_options))
  end

  # Create a group from a set of files by using their UUIDs
  # @param uuids [Array] Array of file UUIDs
  # @param options [Hash] Additional options for group creation
  # @return [Uploadcare::Group] The created group instance
  # @see https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup
  def self.create(uuids:, config: Uploadcare.configuration, request_options: {}, **options)
    upload_group_client = Uploadcare::UploadGroupClient.new(config: config)
    response = Uploadcare::Result.unwrap(
      upload_group_client.create_group(
        uuids: uuids,
        request_options: request_options,
        **options
      )
    )
    new(response, config)
  end

  # Fetch group info by ID.
  #
  # @param group_id [String]
  # @param config [Uploadcare::Configuration]
  # @return [Uploadcare::Group]
  def self.info(group_id:, config: Uploadcare.configuration, request_options: {})
    group_client = Uploadcare::GroupClient.new(config: config)
    response = Uploadcare::Result.unwrap(group_client.info(uuid: group_id, request_options: request_options))
    new(response, config)
  end

  # Returns group ID, extracting from CDN URL if needed.
  #
  # @return [String, nil]
  def id
    return @id if @id
    return unless @cdn_url

    uri = URI.parse(@cdn_url)
    @id = uri.path.split('/').reject(&:empty?).first
    @id
  end

  # Reloads group metadata from the API.
  #
  # @return [Uploadcare::Group]
  def load
    group_with_info = self.class.info(group_id: id, config: @config)
    ATTRIBUTES.each do |attr|
      instance_variable_set("@#{attr}", group_with_info.public_send(attr))
    end
    self
  end

  # Returns the CDN URL for this group.
  #
  # @return [String]
  def cdn_url
    return @cdn_url if @cdn_url && !@cdn_url.empty?

    "#{@config.cdn_base.call}#{id}/"
  end

  # Returns CDN URLs of all files from group without API requesting
  # @return [Array<String>] Array of CDN URLs for all files in the group
  def file_cdn_urls
    files_count.times.map { |file_index| "#{cdn_url}nth/#{file_index}/" }
  end
end
