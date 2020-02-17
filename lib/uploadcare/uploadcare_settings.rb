# frozen_string_literal: true

module Uploadcare
  PUBLIC_KEY = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
  SECRET_KEY = ENV.fetch('UPLOADCARE_SECRET_KEY')
  AUTH_TYPE = 'Uploadcare.Simple'
  SIGN_UPLOADS = false
  UPLOAD_SIGNATURE_LIFETIME = 30 * 60 # seconds
end
