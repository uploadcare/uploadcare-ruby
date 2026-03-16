# frozen_string_literal: true

require 'openssl'

# Generates HMAC-SHA256 signatures for signed uploads.
#
# Used when `config.sign_uploads` is enabled to generate authentication
# signatures for Upload API requests.
#
# @example
#   Uploadcare::Internal::SignatureGenerator.call(config: config)
#   # => { signature: "abc123...", expire: 1234567890 }
module Uploadcare
  module Internal
    class SignatureGenerator
      # Generate signature params for signed uploads.
      #
      # @param config [Uploadcare::Configuration] Configuration with secret key and lifetime
      # @return [Hash] Hash with :signature and :expire keys
      # @raise [ArgumentError] if secret_key is empty or lifetime is invalid
      def self.call(config: Uploadcare.configuration)
        secret_key = config.secret_key.to_s
        lifetime = config.upload_signature_lifetime
        raise ArgumentError, 'secret_key is required for upload signature' if secret_key.empty?
        unless lifetime.is_a?(Integer) && lifetime.positive?
          raise ArgumentError, 'upload_signature_lifetime must be a positive Integer'
        end

        expires_at = Time.now.to_i + lifetime
        signature = OpenSSL::HMAC.hexdigest('sha256', secret_key, expires_at.to_s)
        { signature: signature, expire: expires_at }
      end
    end
  end
end
