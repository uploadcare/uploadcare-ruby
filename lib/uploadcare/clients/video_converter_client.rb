# frozen_string_literal: true

module Uploadcare
  class VideoConverterClient < RestClient
    # Converts a video file to the specified format
    # @param paths [Array<String>] An array of video UUIDs with conversion operations
    # @param options [Hash] Optional parameters such as `store`
    # @return [Hash] The response containing conversion results
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Video/operation/convertVideo
    def convert_video(paths:, options: {}, request_options: {})
      params = { paths: paths }.merge(options)
      post(path: '/convert/video/', params: params, headers: {}, request_options: request_options)
    end

    # Fetches the status of a video conversion job by token
    # @param token [Integer] The job token
    # @return [Hash] The response containing the job status
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/videoConvertStatus
    def status(token:, request_options: {})
      get(path: "/convert/video/status/#{token}/", params: {}, headers: {}, request_options: request_options)
    end
  end
end
