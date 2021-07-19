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
      def self.convert(arr, **options)
        response = Conversion::DocumentConversionClient.new.convert_many(arr, **options)
        response.success
      end

      def self.status(token)
        response = Conversion::DocumentConversionClient.new.get_conversion_status(token)
        response.success
      end
    end
  end
end
