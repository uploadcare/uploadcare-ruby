# frozen_string_literal: true

module Uploadcare
  module Entity
    # This serializer lets a user convert uploaded videos, and usually returns an array of results
    # @see https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/videoConvert
    class VideoConverter < Entity
      client_service Conversion::VideoConversionClient

      # Upload file or group of files from array, File, or url
      #
      # @param object [Array] of hashes with params
      # @param [Hash] of options for conversion
      # @option options [Boolean] :store (false) whether to store file on servers.
      def self.convert(video_params, **options)
        params = video_params.is_a?(Hash) ? [video_params] : video_params
        Conversion::VideoConversionClient.new.convert_many(params, **options)
      end

      def self.status(token)
        Conversion::VideoConversionClient.new.get_conversion_status(token)
      end
    end
  end
end
