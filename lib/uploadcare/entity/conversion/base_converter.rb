# frozen_string_literal:

module Uploadcare
  module Entity
    module Conversion
      # This serializer lets a user convert uploaded documents
      # @see https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/documentConvert
      class BaseConverter < Entity
        class << self
          # Converts files
          #
          # @param doc_params [Array] of hashes with params or [Hash]
          # @option options [Boolean] :store (false) whether to store file on servers.
          def convert(params, options = {})
            files_params = params.is_a?(Hash) ? [params] : params
            conversion_client.new.convert_many(files_params, options)
          end

          # Returns a status of a conversion job
          #
          # @param token [Integer, String] token obtained from a server in convert method
          def status(token)
            conversion_client.new.get_conversion_status(token)
          end

          private

          def conversion_client
            clients[:base]
          end
        end
      end
    end
  end
  include Conversion
end
