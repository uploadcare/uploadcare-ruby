# frozen_string_literal: true

module Uploadcare
  module Param
    module Upload
      class UploadParamsGenerator
        class << self
          def call(options: {}, config: Uploadcare.configuration)
            params = {
              'UPLOADCARE_PUB_KEY' => config.public_key
            }

            store = store_value(options[:store])
            params['UPLOADCARE_STORE'] = store unless store.nil?

            params.merge!(metadata(options: options))
            params.merge!(signature_params(options: options, config: config))

            params.compact
          end

          private

          def store_value(store)
            return nil if store.nil?

            case store
            when true, '1', 1 then '1'
            when false, '0', 0 then '0'
            else store.to_s
            end
          end

          def metadata(options:)
            return {} if options[:metadata].nil?
            raise ArgumentError, 'metadata must be a hash' unless options[:metadata].is_a?(Hash)

            options[:metadata].each_with_object({}) do |(k, v), res|
              res.merge!("metadata[#{k}]" => v.to_s)
            end
          end

          def signature_params(options:, config:)
            return explicit_signature_params(options) if options.key?(:signature)
            return {} unless config.sign_uploads

            signature_data = Upload::SignatureGenerator.call(config: config)
            return { 'signature' => signature_data } unless signature_data.is_a?(Hash)

            params = {}
            params['signature'] = signature_data[:signature] || signature_data['signature']
            params['expire'] = signature_data[:expire] || signature_data['expire']
            params.compact
          end

          def explicit_signature_params(options)
            params = {}
            params['signature'] = options[:signature]
            params['expire'] = options[:expire] if options.key?(:expire)
            params.compact
          end
        end
      end
    end
  end
end
