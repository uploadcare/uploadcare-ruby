# frozen_string_literal: true

module Uploadcare
  class Configuration
    attr_accessor :public_key, :secret_key, :auth_type, :multipart_size_threshold, :rest_api_root,
                  :upload_api_root, :max_request_tries, :base_request_sleep, :max_request_sleep, :sign_uploads,
                  :upload_signature_lifetime, :max_throttle_attempts, :upload_threads, :framework_data,
                  :file_chunk_size, :logger, :cdn_base, :use_subdomains, :cdn_base_postfix

    # Adding Default constants instead of initialization to
    # prevent AssignmentBranchSize violation
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
      logger: ENV['UPLOADCARE_DISABLE_LOGGING'] ? nil : Logger.new($stdout),
      cdn_base: ENV.fetch('UPLOADCARE_CDN_BASE', 'https://ucarecdn.com/'),
      use_subdomains: false,
      cdn_base_postfix: ENV.fetch('UPLOADCARE_CDN_BASE_POSTFIX', 'https://ucarecd.net/')
    }.freeze

    def initialize(options = {})
      DEFAULTS.merge(options).each do |attribute, value|
        send("#{attribute}=", value)
      end
    end

    def cdn_url_base
      return cdn_base unless use_subdomains && public_key && !public_key.empty?

      CnameGenerator.cdn_base_url(public_key, cdn_base_postfix)
    end
  end
end
