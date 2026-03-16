# frozen_string_literal: true

module Uploadcare
  class Client
    class ConversionsAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def documents
        @documents ||= DocumentConversionsAccessor.new(client: client)
      end

      def videos
        @videos ||= VideoConversionsAccessor.new(client: client)
      end
    end
  end
end
