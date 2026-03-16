# frozen_string_literal: true

# REST API endpoint for document conversion operations.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion
class Uploadcare::Api::Rest::DocumentConversions
  # @return [Uploadcare::Api::Rest] Parent REST client
  attr_reader :rest

  # @param rest [Uploadcare::Api::Rest] Parent REST client
  def initialize(rest:)
    @rest = rest
  end

  # Get document format information and possible conversion formats.
  #
  # @param uuid [String] Document file UUID
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Document format info
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/documentConvertInfo
  def info(uuid:, request_options: {})
    rest.get(path: "/convert/document/#{uuid}/", params: {}, headers: {},
             request_options: request_options)
  end

  # Convert a document to a specified format.
  #
  # @param paths [Array<String>] Conversion paths (e.g., ["uuid/document/-/format/pdf/"])
  # @param options [Hash] Optional parameters (:store, :save_in_group)
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Conversion details with result and problems
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/documentConvert
  def convert(paths:, options: {}, request_options: {})
    body = { paths: paths }
    body[:store] = normalize_bool_param(options[:store]) if options.key?(:store)
    body[:save_in_group] = normalize_bool_param(options[:save_in_group]) if options.key?(:save_in_group)

    rest.post(path: '/convert/document/', params: body, headers: {}, request_options: request_options)
  end

  # Get document conversion job status.
  #
  # @param token [String, Integer] Conversion job token
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Job status and result
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/documentConvertStatus
  def status(token:, request_options: {})
    rest.get(path: "/convert/document/status/#{token}/", params: {}, headers: {},
             request_options: request_options)
  end

  private

  def normalize_bool_param(value)
    case value
    when true, 1, '1', 'true' then '1'
    when false, 0, '0', 'false' then '0'
    else value ? '1' : '0'
    end
  end
end
