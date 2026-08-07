# frozen_string_literal: true

require 'uri'

# REST API endpoint for per-file tag operations.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-tags
class Uploadcare::Api::Rest::FileTags
  # @return [Uploadcare::Api::Rest] Parent REST client
  attr_reader :rest

  # @param rest [Uploadcare::Api::Rest] Parent REST client
  def initialize(rest:)
    @rest = rest
  end

  # Get the ordered list of tags for a file.
  #
  # @param uuid [String] File UUID
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Response containing the `tags` array
  def list(uuid:, request_options: {})
    rest.get(path: tags_path(uuid), params: {}, headers: {}, request_options: request_options)
  end
  alias index list

  # Replace all tags for a file.
  #
  # @param uuid [String] File UUID
  # @param tags [Array<String>] Complete replacement tag list
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Response containing tags, added, and deleted
  def replace(uuid:, tags:, request_options: {})
    rest.put(
      path: tags_path(uuid), params: { tags: tags }, headers: {}, request_options: request_options
    )
  end

  # Atomically add and delete tags for a file.
  #
  # Deletions are applied before additions by the API.
  #
  # @param uuid [String] File UUID
  # @param add [Array<String>, nil] Tags to add
  # @param delete [Array<String>, nil] Tags to delete
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Response containing tags, added, and deleted
  def update(uuid:, add: nil, delete: nil, request_options: {})
    params = {}
    params[:add] = add unless add.nil? || add.empty?
    params[:delete] = delete unless delete.nil? || delete.empty?
    body = params.empty? ? {}.to_json : params
    rest.patch(path: tags_path(uuid), params: body, headers: {}, request_options: request_options)
  end

  private

  def tags_path(uuid)
    encoded_uuid = URI.encode_www_form_component(uuid.to_s)
    "/files/#{encoded_uuid}/tags/"
  end
end
