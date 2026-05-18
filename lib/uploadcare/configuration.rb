# frozen_string_literal: true

require 'logger'

# Configuration container for client defaults and per-client overrides.
class Uploadcare::Configuration
  attr_accessor :public_key, :secret_key, :auth_type, :multipart_size_threshold, :rest_api_root,
                :upload_api_root, :max_request_tries, :base_request_sleep, :max_request_sleep, :sign_uploads,
                :upload_signature_lifetime, :max_throttle_attempts, :upload_threads, :framework_data,
                :file_chunk_size, :logger, :use_subdomains, :cdn_base_postfix, :default_cdn_base,
                :multipart_chunk_size, :upload_timeout, :max_upload_retries

  # Default configuration values used as the template for new instances.
  DEFAULTS = {
    public_key: nil,
    secret_key: nil,
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

  # @param options [Hash] Configuration overrides
  def initialize(**options)
    values = DEFAULTS.merge(options)
    values[:public_key] = ENV.fetch('UPLOADCARE_PUBLIC_KEY', '') unless options.key?(:public_key)
    values[:secret_key] = ENV.fetch('UPLOADCARE_SECRET_KEY', '') unless options.key?(:secret_key)

    values.each do |attribute, value|
      send("#{attribute}=", value)
    end
    @logger ||= Logger.new($stdout)
  end

  # Build the deterministic subdomain prefix for the configured public key.
  #
  # @return [String]
  def custom_cname
    Uploadcare::CnameGenerator.generate_cname(public_key: public_key)
  end

  # Resolve the CDN base URL for this configuration.
  #
  # @return [String]
  def cdn_base
    return Uploadcare::CnameGenerator.cdn_base_postfix(config: self) if use_subdomains

    default_cdn_base
  end

  # Clone this configuration with overrides.
  #
  # @param options [Hash]
  # @return [Uploadcare::Configuration]
  def with(**options)
    self.class.new(**to_h, **options)
  end

  # Convert this configuration to a serializable hash.
  #
  # @return [Hash]
  def to_h
    DEFAULTS.keys.to_h { |attribute| [attribute, public_send(attribute)] }
  end
end
