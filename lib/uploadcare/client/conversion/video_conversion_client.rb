# frozen_string_literal: true

require_relative '../rest_client'
require 'param/conversion/video/processing_job_url_builder'
require 'exception/conversion_error'

module Uploadcare
  module Client
    module Conversion
      # This is client for video conversion
      #
      # @see https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/videoConvert
      class VideoConversionClient < RestClient
        def convert_many(arr, **options)
          body = build_body_for_many(arr, options)
          post(uri: '/convert/video/', content: body)
        end

        def get_conversion_status(token)
          get(uri: "/convert/video/status/#{token}/")
        end

        def headers
          {
            'Content-type': 'application/json',
            'Accept': 'application/vnd.uploadcare-v0.6+json',
            'User-Agent': Uploadcare::Param::UserAgent.call
          }
        end

        private

        def success(response)
          body = response.body.to_s
          result = extract_result(body)

          Dry::Monads::Success(result)
        end

        def extract_result(response_body)
          return nil if response_body.nil? || response_body.empty?

          parsed_body = JSON.parse(response_body, symbolize_names: true)
          errors = parsed_body[:error] || parsed_body[:problems]
          raise ConversionError, errors unless errors.nil? || errors.empty?

          parsed_body
        end

        # Prepares body for convert_many method
        def build_body_for_many(arr, options)
          {
            "paths": arr.map do |params|
              Uploadcare::Param::Conversion::Video::ProcessingJobUrlBuilder.call(
                **build_paths_body(params)
              )
            end,
            "store": options[:store] == true ? '1' : '0'
          }.compact.to_json
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
