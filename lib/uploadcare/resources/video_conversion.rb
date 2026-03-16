# frozen_string_literal: true

# Video conversion resource.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Video
module Uploadcare
  module Resources
    class VideoConversion < BaseResource
      attr_accessor :problems, :status, :error, :result

      # Convert a video to a specified format (class method).
      #
      # @param params [Hash] Conversion parameters (:uuid, :format, :quality)
      # @param options [Hash] Optional parameters (:store)
      # @param client [Uploadcare::Client, nil] Client instance
      # @param config [Uploadcare::Configuration] Configuration fallback
      # @param request_options [Hash] Request options
      # @return [Uploadcare::Resources::VideoConversion]
      def self.convert(params:, options: {}, client: nil, config: Uploadcare.configuration, request_options: {})
        raise ArgumentError, 'params must include :uuid' unless params[:uuid]
        raise ArgumentError, 'params must include :format' unless params[:format]
        raise ArgumentError, 'params must include :quality' unless params[:quality]

        paths = Array(params[:uuid]).map do |uuid|
          "#{uuid}/video/-/format/#{params[:format]}/-/quality/#{params[:quality]}/"
        end

        resolved_client = resolve_client(client: client, config: config)
        response = Uploadcare::Result.unwrap(
          resolved_client.api.rest.video_conversions.convert(
            paths: paths, options: options, request_options: request_options
          )
        )
        new(response, resolved_client)
      end

      # Get conversion job status.
      #
      # @param token [String] Job token
      # @param request_options [Hash] Request options
      # @return [self]
      def fetch_status(token:, request_options: {})
        response = Uploadcare::Result.unwrap(
          client.api.rest.video_conversions.status(token: token, request_options: request_options)
        )
        assign_attributes(response)
        self
      end
    end
  end
end
