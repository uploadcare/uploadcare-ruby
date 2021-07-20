# frozen_string_literal: true

module Uploadcare
  module Entity
    # This serializer lets a user convert uploaded documents
    # @see https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/documentConvert
    class DocumentConverter < Entity
      client_service Conversion::DocumentConversionClient

      # Upload file or group of files from array, File, or url
      #
      # @param object [Array] of hashes with params
      # @param [Hash] of options for conversion
      # @option options [Boolean] :store (false) whether to store file on servers.
      def self.convert(doc_params, **options)
        params = doc_params.is_a?(Hash) ? [doc_params] : doc_params
        Conversion::DocumentConversionClient.new.convert_many(params, **options)
      end

      def self.status(token)
        Conversion::DocumentConversionClient.new.get_conversion_status(token)
      end
    end
  end
end
