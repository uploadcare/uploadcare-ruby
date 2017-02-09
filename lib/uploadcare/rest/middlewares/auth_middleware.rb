require 'faraday'

module Uploadcare
  module Connections
    module Request
      class Auth < Faraday::Middleware
        attr_reader :auth_strategy

        def initialize(app=nil, auth_strategy)
          @auth_strategy = auth_strategy
          super(app)
        end

        def call(env)
          auth_strategy.apply(env)
          @app.call(env)
        end

      end
    end
  end
end

Faraday::Request.register_middleware uploadcare_auth: Uploadcare::Connections::Request::Auth
