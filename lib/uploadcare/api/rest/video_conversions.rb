# frozen_string_literal: true

# REST API endpoint for video conversion operations.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Video
class Uploadcare::Api::Rest::VideoConversions
  # @return [Uploadcare::Api::Rest] Parent REST client
  attr_reader :rest

  # @param rest [Uploadcare::Api::Rest] Parent REST client
  def initialize(rest:)
    @rest = rest
  end

  # Convert a video to a specified format.
  #
  # @param paths [Array<String>] Conversion paths (e.g., ["uuid/video/-/format/mp4/-/quality/normal/"])
  # @param options [Hash] Optional parameters (:store)
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Conversion details
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Video/operation/convertVideo
  def convert(paths:, options: {}, request_options: {})
    params = { paths: paths }.merge(options)
    rest.post(path: '/convert/video/', params: params, headers: {}, request_options: request_options)
  end

  # Get video conversion job status.
  #
  # @param token [String, Integer] Conversion job token
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Job status and result
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/videoConvertStatus
  def status(token:, request_options: {})
    rest.get(path: "/convert/video/status/#{token}/", params: {}, headers: {},
             request_options: request_options)
  end
end
