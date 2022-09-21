# frozen_string_literal: true

require 'digest'

module Uploadcare
  module Param
    module Upload
      # This class generates body params for uploads
      class UploadParamsGenerator
        # @see https://uploadcare.com/docs/api_reference/upload/request_based/
        class << self
          def call(**options)
            {
              'UPLOADCARE_PUB_KEY' => Uploadcare.config.public_key,
              'UPLOADCARE_STORE' => store(options[:store]),
              'signature' => (Upload::SignatureGenerator.call if Uploadcare.config.sign_uploads)
            }.merge(metadata(options)).reject { |_k, v| v.nil? }
          end

          private

          def store(store)
            store = 'auto' if store.nil?
            store = '0'    if store == false
            store = '1'    if store == true
            store
          end

          def metadata(**options)
            return {} if options[:metadata].nil?

            options[:metadata].each_with_object({}) do |(k, v), res|
              res.merge!("metadata[#{k}]" => v)
            end
          end
        end
      end
    end
  end
end
