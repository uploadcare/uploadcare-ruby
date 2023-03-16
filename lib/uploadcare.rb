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

# Param
require 'param/webhook_signature_verifier'

# General api
require 'api/api'

# SignedUrlGenerators
require 'signed_url_generators/amakai_generator'
require 'signed_url_generators/base_generator'

# Ruby wrapper for Uploadcare API
#
# @see https://uploadcare.com/docs/api_reference
module Uploadcare
  extend Dry::Configurable

  # NOTE: The dry-configurable gem has introduced the `default` keyword argument
  # and deprecated the positional default argument in v0.13.0, which requires
  # Ruby >= 2.6.0. In order to provide backwards compatibility and not disable
  # deprecation warnings, we override the dry-configurable's `setting` DSL method.
  def self.setting(name, default:, **options, &block)
    if RUBY_VERSION < '2.6'
      super name, default, &block
    else
      super
    end
  end

  setting :public_key,                default: ENV.fetch('UPLOADCARE_PUBLIC_KEY', '')
  setting :secret_key,                default: ENV.fetch('UPLOADCARE_SECRET_KEY', '')
  setting :auth_type,                 default: 'Uploadcare'
  setting :multipart_size_threshold,  default: 100 * 1024 * 1024
  setting :rest_api_root,             default: 'https://api.uploadcare.com'
  setting :upload_api_root,           default: 'https://upload.uploadcare.com'
  setting :max_request_tries,         default: 100
  setting :base_request_sleep,        default: 1 # seconds
  setting :max_request_sleep,         default: 60.0 # seconds
  setting :sign_uploads,              default: false
  setting :upload_signature_lifetime, default: 30 * 60 # seconds
  setting :max_throttle_attempts,     default: 5
  setting :upload_threads,            default: 2 # used for multiupload only ATM
  setting :framework_data,            default: ''
  setting :file_chunk_size,           default: 100
end
