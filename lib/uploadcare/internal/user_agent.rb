# frozen_string_literal: true

# User-Agent string builder for Uploadcare API requests.
#
# Generates a standardized User-Agent header that identifies the Ruby gem version,
# public key, Ruby version, and optional framework information.
#
# @example
#   Uploadcare::Internal::UserAgent.call(config: config)
#   # => "UploadcareRuby/5.0.0/demopublickey (Ruby/3.3.0)"
module Uploadcare
  module Internal
    class UserAgent
      # Build a User-Agent string.
      #
      # @param config [Uploadcare::Configuration] Configuration with public key and framework data
      # @return [String] Formatted User-Agent string
      def self.call(config: Uploadcare.configuration)
        framework_data = config.framework_data.to_s
        framework_suffix = framework_data.empty? ? '' : "; #{framework_data}"
        public_key = config.public_key
        "UploadcareRuby/#{Uploadcare::VERSION}/#{public_key} (Ruby/#{RUBY_VERSION}#{framework_suffix})"
      end
    end
  end
end
