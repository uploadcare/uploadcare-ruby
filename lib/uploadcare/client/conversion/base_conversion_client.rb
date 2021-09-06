# frozen_string_literal: true

require_relative '../rest_client'
require 'exception/conversion_error'

module Uploadcare
  module Client
    module Conversion
      # This is a base client for conversion operations
      #
      # @see https://uploadcare.com/api-refs/rest-api/v0.6.0/#tag/Conversion
      class BaseConversionClient < RestClient
        API_VERSION_HEADER_VALUE = 'application/vnd.uploadcare-v0.5+json'

        def headers
          {
            'Content-Type': 'application/json',
            'Accept': API_VERSION_HEADER_VALUE,
            'User-Agent': Uploadcare::Param::UserAgent.call
          }
        end

        private

        def send_convert_request(arr, options, url_builder_class)
          body = build_body_for_many(arr, options, url_builder_class)
          post(uri: convert_uri, content: body)
        end

        def success(response)
          body = response.body.to_s
          extract_result(body)
        end

        def extract_result(response_body)
          return if response_body.empty?

          parsed_body = JSON.parse(response_body, symbolize_names: true)
          errors = parsed_body[:error] || parsed_body[:problems]
          return Dry::Monads::Failure(errors) unless errors.nil? || errors.empty?

          Dry::Monads::Success(parsed_body)
        end

        # Prepares body for convert_many method
        def build_body_for_many(arr, options, url_builder_class)
          {
            paths: arr.map do |params|
              url_builder_class.call(
                **build_paths_body(params)
              )
            end,
            store: options[:store]
          }.compact.to_json
        end
      end
    end
  end
end
