module Uploadcare
  # Determines User-Agent string either taking it from settings or building
  # in accordance with common Uploadcare format
  #
  class UserAgent
    # @param options [Hash]
    # @option options [String] :user_agent (nil)
    # @option options [String] :public_key (nil)
    # @option options [String] :user_agent_environment (nil)
    # @return [String]
    #
    def call(options)
      return options[:user_agent].to_s if options[:user_agent]

      user_agent_string(
        options.fetch(:public_key, nil),
        options.fetch(:user_agent_environment, {})
      )
    end

    private

    def user_agent_string(public_key, extensions)
      format(
        '%<library>s/%<pubkey>s (%<environment>s)',
        library: versioned('UploadcareRuby', Uploadcare::VERSION),
        pubkey: public_key,
        environment: environment_string(extensions)
      )
    end

    def environment_string(extensions)
      [
        versioned('Ruby', Gem.ruby_version),
        versioned(extensions[:framework_name], extensions[:framework_version]),
        versioned(extensions[:extension_name], extensions[:extension_version])
      ].compact.join('; ')
    end

    def versioned(name, version = nil)
      name ? [name, version].compact.join('/') : nil
    end
  end
end
