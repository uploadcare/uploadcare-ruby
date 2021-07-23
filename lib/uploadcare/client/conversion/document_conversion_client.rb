# frozen_string_literal: true

require 'client/conversion/base_conversion_client'
require 'param/conversion/document/processing_job_url_builder'

module Uploadcare
  module Client
    module Conversion
      # This is client for document conversion
      #
      # @see https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/documentConvert
      class DocumentConversionClient < BaseConversionClient
        def convert_many(
          arr,
          options = {},
          url_builder_class = Uploadcare::Param::Conversion::Document::ProcessingJobUrlBuilder
        )
          body = build_body_for_many(arr, options, url_builder_class)
          post(uri: '/convert/document/', content: body)
        end

        def get_conversion_status(token)
          get(uri: "/convert/document/status/#{token}/")
        end

        private

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
