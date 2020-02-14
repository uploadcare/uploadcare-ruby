# frozen_string_literal: true

require 'digest'

module Uploadcare
  module Upload
    # This class generates body params for uploads
    # https://uploadcare.com/docs/api_reference/upload/request_based/
    class UploadParamsGenerator
      def self.call(store = false)
        {
          'UPLOADCARE_PUB_KEY': PUBLIC_KEY,
          'UPLOADCARE_STORE': (store == true) ? '1' : '0',
          'signature': (Upload::SignatureGenerator.call if SIGN_UPLOADS)
        }.reject{ |k, v| v.nil? }
      end
    end
  end
end
