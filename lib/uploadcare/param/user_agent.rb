# frozen_string_literal: true

module Uploadcare
  module Param
    # This header is added to track libraries using Uploadcare API
    class UserAgent
      # Generate header from Gem's config
      #
      # @example Uploadcare::Param::UserAgent.call
      #   UploadcareRuby/3.0.0-dev/Pubkey_(Ruby/2.6.3;UploadcareRuby)
      def self.call
        framework_data = Uploadcare.configuration.framework_data || ''
        framework_data_string = '; ' + Uploadcare.configuration.framework_data unless framework_data.empty?
        public_key = Uploadcare.configuration.public_key
        "UploadcareRuby/#{VERSION}/#{public_key} (Ruby/#{RUBY_VERSION}#{framework_data_string})"
      end
    end
  end
end
