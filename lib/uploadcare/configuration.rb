# frozen_string_literal: true

require 'logger'

# Configuration class for Uploadcare client
#
# Manages all configuration options for both REST API and Upload API clients.
# Configuration can be set via environment variables or directly in code.
#
# @example Configure via environment variables
#   ENV['UPLOADCARE_PUBLIC_KEY'] = 'your_public_key'
#   ENV['UPLOADCARE_SECRET_KEY'] = 'your_secret_key'
#
# @example Configure in code
#   Uploadcare.configuration.public_key = 'your_public_key'
#   Uploadcare.configuration.secret_key = 'your_secret_key'
#   Uploadcare.configuration.upload_timeout = 120
class Uploadcare::Configuration
  # @!attribute public_key
  #   @return [String] Uploadcare project public key
  # @!attribute secret_key
  #   @return [String] Uploadcare project secret key
  # @!attribute auth_type
  #   @return [String] authentication type (default: 'Uploadcare')
  # @!attribute multipart_size_threshold
  #   @return [Integer] file size threshold for multipart upload in bytes (default: 100MB)
  # @!attribute rest_api_root
  #   @return [String] REST API base URL
  # @!attribute upload_api_root
  #   @return [String] Upload API base URL
  # @!attribute max_request_tries
  #   @return [Integer] maximum number of request retry attempts
  # @!attribute base_request_sleep
  #   @return [Integer] base sleep time between retries in seconds
  # @!attribute max_request_sleep
  #   @return [Float] maximum sleep time between retries in seconds
  # @!attribute sign_uploads
  #   @return [Boolean] whether to sign upload requests
  # @!attribute upload_signature_lifetime
  #   @return [Integer] upload signature lifetime in seconds
  # @!attribute max_throttle_attempts
  #   @return [Integer] maximum number of throttle retry attempts
  # @!attribute upload_threads
  #   @return [Integer] number of threads for multipart upload
  # @!attribute framework_data
  #   @return [String] framework identification data
  # @!attribute file_chunk_size
  #   @return [Integer] chunk size for file operations
  # @!attribute logger
  #   @return [Logger] logger instance
  # @!attribute multipart_chunk_size
  #   @return [Integer] chunk size for multipart uploads in bytes (default: 5MB)
  # @!attribute upload_timeout
  #   @return [Integer] upload request timeout in seconds (default: 60)
  # @!attribute max_upload_retries
  #   @return [Integer] maximum number of upload retry attempts (default: 3)
  attr_accessor :public_key, :secret_key, :auth_type, :multipart_size_threshold, :rest_api_root,
                :upload_api_root, :max_request_tries, :base_request_sleep, :max_request_sleep, :sign_uploads,
                :upload_signature_lifetime, :max_throttle_attempts, :upload_threads, :framework_data,
                :file_chunk_size, :logger, :use_subdomains, :cdn_base_postfix, :default_cdn_base,
                :multipart_chunk_size, :upload_timeout, :max_upload_retries

  # Default configuration values
  #
  # These defaults are used when initializing a new configuration instance.
  # Values can be overridden via environment variables or direct assignment.
  DEFAULTS = {
    public_key: ENV.fetch('UPLOADCARE_PUBLIC_KEY', ''),
    secret_key: ENV.fetch('UPLOADCARE_SECRET_KEY', ''),
    auth_type: 'Uploadcare',
    multipart_size_threshold: 100 * 1024 * 1024,
    rest_api_root: 'https://api.uploadcare.com',
    upload_api_root: 'https://upload.uploadcare.com',
    max_request_tries: 100,
    base_request_sleep: 1,         # seconds
    max_request_sleep: 60.0,       # seconds
    sign_uploads: false,
    upload_signature_lifetime: 30 * 60, # seconds
    max_throttle_attempts: 5,
    upload_threads: 2, # used for multiupload only ATM
    framework_data: '',
    file_chunk_size: 100,
    logger: nil,
    use_subdomains: false,
    cdn_base_postfix: 'https://ucarecd.net/',
    default_cdn_base: 'https://ucarecdn.com/',
    multipart_chunk_size: 5 * 1024 * 1024, # 5MB chunks for multipart upload
    upload_timeout: 60,            # seconds
    max_upload_retries: 3          # retry failed uploads 3 times
  }.freeze

  # Initialize a new configuration instance
  #
  # @param options [Hash] configuration options to override defaults
  # @return [Uploadcare::Configuration] new configuration instance
  def initialize(**options)
    DEFAULTS.merge(options).each do |attribute, value|
      send("#{attribute}=", value)
    end
    @logger ||= Logger.new($stdout)
  end

  # Returns the custom CNAME for the account
  # @return [String] The generated CNAME prefix
  def custom_cname
    Uploadcare::CnameGenerator.generate_cname(public_key: public_key)
  end

  # Returns the CDN base URL based on subdomain configuration
  # @return [Proc] A proc that returns the appropriate CDN base URL
  def cdn_base
    lambda do
      if use_subdomains
        Uploadcare::CnameGenerator.cdn_base_postfix(config: self)
      else
        default_cdn_base
      end
    end
  end
end
