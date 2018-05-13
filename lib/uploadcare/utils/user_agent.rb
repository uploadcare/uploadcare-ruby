module Uploadcare
  # Determines User-Agent string either taking it from settings or building
  # in accordance with common Uploadcare format
  #
  class UserAgent
    # @param options [Hash]
    # @option options [String] :user_agent (nil)
    # @option options [String] :public_key (nil)
    # @option options [String] :user_agent_extension (nil)
    # @return [String]
    #
    def call(options)
      return options[:user_agent].to_s if options[:user_agent]
      user_agent_string(options)
    end

    private

    def user_agent_string(options)
      format(
        '%<library_string>s/%<public_key>s (%<environment_string>s)',
        library_string: "UploadcareRuby/#{Uploadcare::VERSION}",
        public_key: options.fetch(:public_key, nil),
        environment_string: environment_string(options)
      )
    end

    def environment_string(options)
      [
        "Ruby/#{Gem.ruby_version};",
        options.fetch(:user_agent_extension, nil)
      ].compact.join(' ')
    end
  end
end
