module Uploadcare
  module Param
    # This header is added to track libraries using Uploadcare API
    #
    # @example Uploadcare::Param::UserAgent.call
    #   UploadcareRuby/3.0.0-dev/Pubkey_(Ruby/2.6.3;UploadcareRuby)
    class UserAgent
      # Generate header from Gem's config
      def self.call
        framework_data = Uploadcare.configuration.framework_data
        "UploadcareRuby/#{VERSION}/Pubkey_(Ruby/#{RUBY_VERSION}\;#{framework_data})"
      end
    end
  end
end
