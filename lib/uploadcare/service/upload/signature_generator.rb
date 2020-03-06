# frozen_string_literal: true

require 'digest'

module Uploadcare
  module Upload
    # This class generates signatures for protected uploads
    # https://uploadcare.com/docs/api_reference/upload/signed_uploads/
    class SignatureGenerator
      def self.call
        expires_at = Time.now.to_i + Uploadcare.configuration.upload_signature_lifetime
        to_sign = Uploadcare.configuration.secret_key + expires_at.to_s
        signature = Digest::MD5.hexdigest(to_sign)
        {
          'signature': signature,
          'expire': expires_at
        }
      end
    end
  end
end
