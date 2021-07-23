# frozen_string_literal: true

require 'client/conversion/base_conversion_client'
require 'param/conversion/video/processing_job_url_builder'

module Uploadcare
  module Client
    module Conversion
      # This is client for video conversion
      #
      # @see https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/videoConvert
      class VideoConversionClient < BaseConversionClient
        def convert_many(
          arr,
          options = {},
          url_builder_class = Uploadcare::Param::Conversion::Video::ProcessingJobUrlBuilder
        )
          body = build_body_for_many(arr, options, url_builder_class)
          post(uri: '/convert/video/', content: body)
        end

        def get_conversion_status(token)
          get(uri: "/convert/video/status/#{token}/")
        end

        private

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
