# frozen_string_literal: true

# Document conversion resource.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion
module Uploadcare
  module Resources
    class DocumentConversion < BaseResource
      attr_accessor :error, :format, :converted_groups, :status, :result

      # Get document format info and possible conversions.
      #
      # @param uuid [String] Document file UUID
      # @param request_options [Hash] Request options
      # @return [self]
      def info(uuid:, request_options: {})
        response = Uploadcare::Result.unwrap(
          client.api.rest.document_conversions.info(uuid: uuid, request_options: request_options)
        )
        assign_attributes(response)
        self
      end

      # Convert a document to a specified format (class method).
      #
      # @param params [Hash] Conversion parameters (:uuid, :format)
      # @param options [Hash] Optional parameters (:store, :save_in_group)
      # @param client [Uploadcare::Client, nil] Client instance
      # @param config [Uploadcare::Configuration] Configuration fallback
      # @param request_options [Hash] Request options
      # @return [Hash] Conversion response
      def self.convert_document(params:, options: {}, client: nil, config: Uploadcare.configuration,
                                request_options: {})
        resolved_client = resolve_client(client: client, config: config)
        paths = Array(params[:uuid]).map do |uuid|
          "#{uuid}/document/-/format/#{params[:format]}/"
        end

        Uploadcare::Result.unwrap(
          resolved_client.api.rest.document_conversions.convert(
            paths: paths, options: options, request_options: request_options
          )
        )
      end

      def self.status(token:, client: nil, config: Uploadcare.configuration, request_options: {})
        resolved_client = resolve_client(client: client, config: config)
        new({}, resolved_client).fetch_status(token: token, request_options: request_options)
      end

      def self.info_for(uuid:, client: nil, config: Uploadcare.configuration, request_options: {})
        resolved_client = resolve_client(client: client, config: config)
        new({}, resolved_client).info(uuid: uuid, request_options: request_options)
      end

      # Get conversion job status.
      #
      # @param token [String] Job token
      # @param request_options [Hash] Request options
      # @return [self]
      def fetch_status(token:, request_options: {})
        response = Uploadcare::Result.unwrap(
          client.api.rest.document_conversions.status(token: token, request_options: request_options)
        )
        assign_attributes(response)
        self
      end
    end
  end
end
