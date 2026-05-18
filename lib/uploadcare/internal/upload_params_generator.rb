# frozen_string_literal: true

# Generates upload parameters for Upload API requests.
#
# Builds the parameter hash needed for file uploads, including public key,
# store preferences, metadata, and optional signature params.
class Uploadcare::Internal::UploadParamsGenerator
  class << self
    # Build upload parameters.
    #
    # @param options [Hash] Upload options (:store, :metadata, :signature, :expire)
    # @param config [Uploadcare::Configuration] Configuration with public key and signing settings
    # @return [Hash] Upload parameters hash
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

    # Convert store option to API format.
    #
    # @param store [Boolean, String, Integer, nil] Store option value
    # @return [String, nil] Formatted store value ('0', '1', or nil)
    def store_value(store)
      return nil if store.nil?

      case store
      when true, '1', 1 then '1'
      when false, '0', 0 then '0'
      else store.to_s
      end
    end

    # Generate metadata parameters from options hash.
    #
    # @param options [Hash] Options containing :metadata key
    # @return [Hash] Metadata params formatted as "metadata[key]" => "value"
    def metadata(options:)
      return {} if options[:metadata].nil?
      raise ArgumentError, 'metadata must be a hash' unless options[:metadata].is_a?(Hash)

      options[:metadata].each_with_object({}) do |(k, v), res|
        res["metadata[#{k}]"] = v.to_s
      end
    end

    # Generate signature parameters for signed uploads.
    #
    # @param options [Hash] Options with optional :signature and :expire keys
    # @param config [Uploadcare::Configuration] Configuration with signing settings
    # @return [Hash] Signature parameters
    def signature_params(options:, config:)
      return explicit_signature_params(options) if options.key?(:signature)
      return {} unless config.sign_uploads

      signature_data = Uploadcare::Internal::SignatureGenerator.call(config: config)
      return { 'signature' => signature_data } unless signature_data.is_a?(Hash)

      params = {}
      params['signature'] = signature_data[:signature] || signature_data['signature']
      params['expire'] = signature_data[:expire] || signature_data['expire']
      params.compact
    end

    # Extract explicit signature params from options.
    #
    # @param options [Hash] Options with :signature and optional :expire
    # @return [Hash] Signature parameters
    def explicit_signature_params(options)
      params = {}
      params['signature'] = options[:signature]
      params['expire'] = options[:expire] if options.key?(:expire)
      params.compact
    end
  end
end
