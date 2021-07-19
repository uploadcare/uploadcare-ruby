# frozen_string_literal: true

require_relative '../rest_client'
require 'param/conversion/document/processing_job_url_builder'

module Uploadcare
  module Client
    module Conversion
      # This is client for document conversion
      #
      # @see https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/documentConvert
      class DocumentConversionClient < RestClient
        def convert_many(arr, **options)
          body = build_body_for_many(arr, options)
          post(uri: '/convert/document/', content: body)
        end

        def get_conversion_status(token)
          get(uri: "/convert/document/status/#{token}/")
        end

        def headers
          {
            'Content-type': 'application/json',
            'Accept': 'application/vnd.uploadcare-v0.6+json',
            'User-Agent': Uploadcare::Param::UserAgent.call
          }
        end

        private

        # Prepares body for convert_many method
        def build_body_for_many(arr, options)
          check_array_param(arr)
          {
            "paths": arr.map do |params|
              Uploadcare::Param::Conversion::Document::ProcessingJobUrlBuilder.call(
                **build_paths_body(params)
              )
            end,
            "store": options[:store] == true ? '1' : '0'
          }.compact.to_json
        end

        def build_paths_body(params)
          {
            uuid: params[:uuid],
            format: params[:format],
            page: params[:page]
          }.compact
        end

        def check_array_param(arr)
          raise Uploadcare::Exception::ValidationError, 'First argument must be an Array' unless arr.is_a?(Array)
        end
      end
    end
  end
end
