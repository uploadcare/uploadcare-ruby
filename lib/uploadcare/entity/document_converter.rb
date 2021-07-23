# frozen_string_literal: true

module Uploadcare
  module Entity
    # This serializer lets a user convert uploaded documents
    # @see https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/documentConvert
    class DocumentConverter < Entity
      client_service Conversion::DocumentConversionClient
      # Converts documents
      #
      # @param doc_params [Array] of hashes with params or [Hash]
      # @option options [Boolean] :store (false) whether to store file on servers.
      def self.convert(doc_params, **options)
        params = doc_params.is_a?(Hash) ? [doc_params] : doc_params
        Conversion::DocumentConversionClient.new.convert_many(params, **options)
      end

      # Returns a status of document conversion job
      #
      # @param token [Integer, String] token obtained from a server in convert method
      def self.status(token)
        Conversion::DocumentConversionClient.new.get_conversion_status(token)
      end
    end
  end
end
