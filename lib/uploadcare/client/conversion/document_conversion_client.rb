# frozen_string_literal: true

require 'client/conversion/base_conversion_client'
require 'param/conversion/document/processing_job_url_builder'

module Uploadcare
  module Client
    module Conversion
      # This is client for document conversion
      #
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/documentConvert
      class DocumentConversionClient < BaseConversionClient
        def convert_many(
          arr,
          options = {},
          url_builder_class = Param::Conversion::Document::ProcessingJobUrlBuilder
        )
          send_convert_request(arr, options, url_builder_class)
        end

        def get_conversion_status(token)
          get(uri: "/convert/document/status/#{token}/")
        end

        private

        def convert_uri
          '/convert/document/'
        end

        def build_paths_body(params)
          {
            uuid: params[:uuid],
            format: params[:format],
            page: params[:page]
          }.compact
        end
      end
    end
  end
end
