# frozen_string_literal: true

require 'uri'

# Group resource representing a collection of files in Uploadcare.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group
class Uploadcare::Resources::Group < Uploadcare::Resources::BaseResource
  # API fields assigned onto group resources.
  ATTRIBUTES = %i[
    id datetime_removed datetime_stored datetime_uploaded is_image is_ready mime_type original_file_url cdn_url
    original_filename size url uuid variations content_info metadata appdata source datetime_created files_count
    files
  ].freeze

  attr_writer :id, :cdn_url
  attr_accessor :datetime_removed, :datetime_stored, :datetime_uploaded, :is_image, :is_ready, :mime_type,
                :original_file_url, :original_filename, :size, :url, :uuid, :variations,
                :content_info, :metadata, :appdata, :source, :datetime_created, :files_count, :files

  # --- Class methods ---

  # List groups with optional filtering and pagination.
  #
  # @param params [Hash] Query parameters
  # @param client [Uploadcare::Client, nil] Client instance
  # @param config [Uploadcare::Configuration] Configuration fallback
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Collections::Paginated]
  def self.list(params: {}, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    response = Uploadcare::Result.unwrap(
      resolved_client.api.rest.groups.list(params: params, request_options: request_options)
    )
    groups = response['results'].map { |data| new(data, resolved_client) }

    Uploadcare::Collections::Paginated.new(
      resources: groups,
      next_page: response['next'],
      previous_page: response['previous'],
      per_page: response['per_page'],
      total: response['total'],
      api_client: resolved_client.api.rest.groups,
      resource_class: self,
      client: resolved_client,
      request_options: request_options
    )
  end

  # Find a group by ID.
  #
  # @param group_id [String] Group UUID (formatted as UUID~size)
  # @param client [Uploadcare::Client, nil] Client instance
  # @param config [Uploadcare::Configuration] Configuration fallback
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Resources::Group]
  def self.find(group_id:, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    response = Uploadcare::Result.unwrap(
      resolved_client.api.rest.groups.info(uuid: group_id, request_options: request_options)
    )
    new(response, resolved_client)
  end

  class << self
    alias retrieve find
    alias info find
  end

  # Create a group from file UUIDs.
  #
  # @param uuids [Array<String>] File UUIDs
  # @param client [Uploadcare::Client, nil] Client instance
  # @param config [Uploadcare::Configuration] Configuration fallback
  # @param options [Hash] Additional options
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Resources::Group]
  def self.create(uuids:, client: nil, config: Uploadcare.configuration, request_options: {}, **options)
    resolved_client = resolve_client(client: client, config: config)
    response = Uploadcare::Result.unwrap(
      resolved_client.api.upload.groups.create(
        files: uuids, request_options: request_options, **options
      )
    )
    new(response, resolved_client)
  end

  # --- Instance methods ---

  # Reload group information from the API.
  #
  # @param request_options [Hash] Request options
  # @return [self]
  def reload(request_options: {})
    response = Uploadcare::Result.unwrap(
      client.api.rest.groups.info(uuid: id, request_options: request_options)
    )
    assign_attributes(response)
    self
  end
  alias load reload

  # Delete this group.
  #
  # @param request_options [Hash] Request options
  # @return [nil]
  def delete(request_options: {})
    Uploadcare::Result.unwrap(
      client.api.rest.groups.delete(uuid: id, request_options: request_options)
    )
  end

  # Returns group ID, extracting from CDN URL if needed.
  #
  # @return [String, nil]
  def id
    return @id if @id
    return @uuid if defined?(@uuid) && !@uuid.to_s.empty?
    return unless @cdn_url

    uri = URI.parse(@cdn_url)
    @id = uri.path.split('/').reject(&:empty?).first
  end

  # Returns the CDN URL for this group.
  #
  # @return [String]
  def cdn_url
    return @cdn_url if @cdn_url && !@cdn_url.empty?

    "#{config.cdn_base}#{id}/"
  end

  # Returns CDN URLs for all files in the group.
  #
  # @return [Array<String>]
  def file_cdn_urls
    return [] if files_count.nil?

    files_count.times.map { |i| "#{cdn_url}nth/#{i}/" }
  end
end
