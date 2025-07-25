# frozen_string_literal: true

module Uploadcare
  module Middleware
    class Base
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      end
    end
  end
end
