# frozen_string_literal: true

require 'openssl'

module Uploadcare
  # This object verifies a signature received along with webhook headers
  # For v4.4.3 compatibility, accessible as Uploadcare::Param::WebhookSignatureVerifier
  class WebhookSignatureVerifier
    # @see https://uploadcare.com/docs/security/secure-webhooks/
    def self.valid?(options = {})
      webhook_body_json = options[:webhook_body]
      signing_secret = options[:signing_secret] || ENV.fetch('UC_SIGNING_SECRET', nil)
      x_uc_signature_header = options[:x_uc_signature_header]

      digest = OpenSSL::Digest.new('sha256')

      calculated_signature = "v1=#{OpenSSL::HMAC.hexdigest(digest, signing_secret, webhook_body_json)}"

      calculated_signature == x_uc_signature_header
    end
  end

  # v4.4.3 compatibility namespace alias
  module Param
    WebhookSignatureVerifier = Uploadcare::WebhookSignatureVerifier
  end
end
