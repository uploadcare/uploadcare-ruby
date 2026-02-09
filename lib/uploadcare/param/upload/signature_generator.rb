# frozen_string_literal: true

require 'openssl'

# Signature generator for signed uploads.
class Uploadcare::Param::Upload::SignatureGenerator
  # Generate signature params.
  #
  # @param config [Uploadcare::Configuration]
  # @return [Hash]
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
