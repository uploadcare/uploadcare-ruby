# frozen_string_literal: true

module Uploadcare
  PUBLIC_KEY = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
  SECRET_KEY = ENV.fetch('UPLOADCARE_SECRET_KEY')
  AUTH_TYPE = 'Uploadcare.Simple'
  MULTIPART_SIZE_THRESHOLD = 100 * 1024 * 1024
  REST_API_ROOT = 'https://api.uploadcare.com'
  UPLOAD_API_ROOT = 'https://upload.uploadcare.com'
  MAX_REQUEST_TRIES = 100
  BASE_REQUEST_SLEEP = 1 # seconds
  MAX_REQUEST_SLEEP = 60.0 # seconds
  SIGN_UPLOADS = false
  UPLOAD_SIGNATURE_LIFETIME = 30 * 60 # seconds
end
