# frozen_string_literal: true

require 'digest'

module Uploadcare
  module Param
    module Upload
      class SignatureGenerator
        def self.call(config: Uploadcare.configuration)
          expires_at = Time.now.to_i + config.upload_signature_lifetime
          to_sign = config.secret_key.to_s + expires_at.to_s
          signature = Digest::MD5.hexdigest(to_sign)
          { signature: signature, expire: expires_at }
        end
      end
    end
  end
end
