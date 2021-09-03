# frozen_string_literal: true

require_relative 'base_converter'

module Uploadcare
  module Entity
    module Conversion
      # This serializer lets a user convert uploaded videos, and usually returns an array of results
      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/videoConvert
      class VideoConverter < BaseConverter
        client_service Client::Conversion::VideoConversionClient
      end
    end
  end
end
