# frozen_string_literal: true

require 'digest'

module Uploadcare
  module Param
    module Upload
      # This class generates signatures for protected uploads
      class SignatureGenerator
        # @see https://uploadcare.com/docs/api_reference/upload/signed_uploads/
        # @return [Hash] signature and its expiration time
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
end
