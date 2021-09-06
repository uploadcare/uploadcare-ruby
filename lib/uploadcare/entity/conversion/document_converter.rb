# frozen_string_literal: true

require_relative 'base_converter'

module Uploadcare
  module Entity
    module Conversion
      # This serializer lets a user convert uploaded documents
      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/documentConvert
      class DocumentConverter < BaseConverter
        client_service Client::Conversion::DocumentConversionClient
      end
    end
  end
end
