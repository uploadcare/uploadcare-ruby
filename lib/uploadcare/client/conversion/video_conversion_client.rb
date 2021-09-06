# frozen_string_literal: true

require 'client/conversion/base_conversion_client'
require 'param/conversion/video/processing_job_url_builder'
require 'exception/conversion_error'

module Uploadcare
  module Client
    module Conversion
      # This is client for video conversion
      #
      # @see https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/videoConvert
      class VideoConversionClient < BaseConversionClient
        def convert_many(
          params,
          options = {},
          url_builder_class = Param::Conversion::Video::ProcessingJobUrlBuilder
        )
          video_params = params.is_a?(Hash) ? [params] : params
          send_convert_request(video_params, options, url_builder_class)
        end

        def get_conversion_status(token)
          get(uri: "/convert/video/status/#{token}/")
        end

        private

        def convert_uri
          '/convert/video/'
        end

        def build_paths_body(params)
          {
            uuid: params[:uuid],
            quality: params[:quality],
            format: params[:format],
            size: params[:size],
            cut: params[:cut],
            thumbs: params[:thumbs]
          }.compact
        end
      end
    end
  end
end
