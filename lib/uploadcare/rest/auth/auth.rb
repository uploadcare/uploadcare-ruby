module Uploadcare
  module Connections
    module Auth

      def self.strategy(options)
        auth_scheme = options.fetch(:auth_scheme)

        unless [:simple, :secure].include?(auth_scheme)
          raise ArgumentError, "Unknown auth_scheme: '#{auth_scheme}'"
        end

        klass = const_get(auth_scheme.capitalize)
        klass.new(options)
      end

      class Base
        attr_reader :public_key, :private_key

        def initialize(options)
          @public_key = options.fetch(:public_key)
          @private_key = options.fetch(:private_key)
        end

        def apply(env)
          raise NotImplementedError
        end
      end

    end
  end
end
