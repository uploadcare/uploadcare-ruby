# frozen_string_literal = true

require 'uploadcare_configuration'

Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
  config.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY')
  config.auth_type = 'Uploadcare.Simple'
  config.multipart_size_threshold = 100 * 1024 * 1024
  config.rest_api_root = 'https://api.uploadcare.com'
  config.upload_api_root = 'https://upload.uploadcare.com'
  config.max_request_tries = 100
  config.base_request_sleep = 1 # seconds
  config.max_request_sleep = 60.0 # seconds
  config.sign_uploads = false
  config.upload_signature_lifetime = 30 * 60 # seconds
  config.max_throttle_attempts = 5
  config.upload_threads = 2 # used for multiupload only ATM
  config.framework_data = ''
end
