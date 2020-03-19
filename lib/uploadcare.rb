# frozen_string_literal: true

# Gem version
require 'ruby/version'

# Exceptions
require 'exception/throttle_error'
require 'exception/request_error'

# Entities
require 'entity/entity'
require 'entity/file'
require 'entity/file_list'
require 'entity/group'
require 'entity/group_list'
require 'entity/project'
require 'entity/uploader'
require 'entity/webhook'

# General api
require 'api/api'

# Ruby wrapper for Uploadcare API
#
# @see https://uploadcare.com/docs/api_reference
module Uploadcare
  extend Dry::Configurable
  setting :public_key, ENV.fetch('UPLOADCARE_PUBLIC_KEY')
  setting :secret_key, ENV.fetch('UPLOADCARE_SECRET_KEY')
  setting :auth_type, 'Uploadcare'
  setting :multipart_size_threshold, 100 * 1024 * 1024
  setting :rest_api_root, 'https://api.uploadcare.com'
  setting :upload_api_root, 'https://upload.uploadcare.com'
  setting :max_request_tries, 100
  setting :base_request_sleep, 1 # seconds
  setting :max_request_sleep, 60.0 # seconds
  setting :sign_uploads, false
  setting :upload_signature_lifetime, 30 * 60 # seconds
  setting :max_throttle_attempts, 5
  setting :upload_threads, 2 # used for multiupload only ATM
  setting :framework_data, ''
end
