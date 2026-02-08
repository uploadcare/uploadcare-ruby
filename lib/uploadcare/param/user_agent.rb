# frozen_string_literal: true

module Uploadcare
  module Param
    class UserAgent
      def self.call(config: Uploadcare.configuration)
        framework_data = config.framework_data.to_s
        framework_suffix = framework_data.empty? ? '' : "; #{framework_data}"
        public_key = config.public_key
        "UploadcareRuby/#{Uploadcare::VERSION}/#{public_key} (Ruby/#{RUBY_VERSION}#{framework_suffix})"
      end
    end
  end
end
