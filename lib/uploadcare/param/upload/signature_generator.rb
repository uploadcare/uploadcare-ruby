# frozen_string_literal: true

require 'digest'

module Uploadcare
  module Param
    module Upload
      class SignatureGenerator
        def self.call(config: Uploadcare.configuration)
          secret_key = config.secret_key.to_s
          lifetime = config.upload_signature_lifetime
          raise ArgumentError, 'secret_key is required for upload signature' if secret_key.empty?
          unless lifetime.is_a?(Integer) && lifetime.positive?
            raise ArgumentError, 'upload_signature_lifetime must be a positive Integer'
          end

          expires_at = Time.now.to_i + lifetime
          to_sign = secret_key + expires_at.to_s
          signature = Digest::MD5.hexdigest(to_sign)
          { signature: signature, expire: expires_at }
        end
      end
    end
  end
end
