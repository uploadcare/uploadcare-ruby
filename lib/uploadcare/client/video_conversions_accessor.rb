# frozen_string_literal: true

module Uploadcare
  class Client
    class VideoConversionsAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def convert(uuid:, format:, quality:, options: {}, request_options: {})
        Uploadcare::Resources::VideoConversion.convert(
          params: { uuid: uuid, format: format, quality: quality }, options: options, client: client,
          request_options: request_options
        )
      end

      def status(token:, request_options: {})
        Uploadcare::Resources::VideoConversion.status(
          token: token, client: client, request_options: request_options
        )
      end
    end
  end
end
