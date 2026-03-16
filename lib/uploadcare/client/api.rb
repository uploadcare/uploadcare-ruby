# frozen_string_literal: true

module Uploadcare
  class Client
    class Api
      attr_reader :config

      def initialize(config:)
        @config = config
      end

      def rest
        @rest ||= Uploadcare::Api::Rest.new(config: config)
      end

      def upload
        @upload ||= Uploadcare::Api::Upload.new(config: config)
      end
    end
  end
end
