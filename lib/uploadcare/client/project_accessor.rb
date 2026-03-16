# frozen_string_literal: true

module Uploadcare
  class Client
    class ProjectAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def current(request_options: {})
        Uploadcare::Resources::Project.current(client: client, request_options: request_options)
      end
    end
  end
end
