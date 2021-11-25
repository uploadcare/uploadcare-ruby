# frozen_string_literal: true

require 'digest/md5'

module Uploadcare
  module Param
    # This object verifies a signature received along with webhook headers
    class WebhookSignatureVerifier
      # @see https://uploadcare.com/docs/security/secure-webhooks/
      def self.valid?(options = {})
        webhook_body_json = options[:webhook_body]
        signing_secret = options[:signing_secret] || ENV['UC_SIGNING_SECRET']
        x_uc_signature_header = options[:x_uc_signature_header]

        digest = OpenSSL::Digest.new('sha256')

        calculated_signature = "v1=#{OpenSSL::HMAC.hexdigest(digest, signing_secret, webhook_body_json)}"

        calculated_signature == x_uc_signature_header
      end
    end
  end
end
