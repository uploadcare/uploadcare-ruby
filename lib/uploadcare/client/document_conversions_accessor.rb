# frozen_string_literal: true

module Uploadcare
  class Client
    class DocumentConversionsAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def convert(uuid:, format:, options: {}, request_options: {})
        Uploadcare::Resources::DocumentConversion.convert_document(
          params: { uuid: uuid, format: format }, options: options, client: client,
          request_options: request_options
        )
      end

      def status(token:, request_options: {})
        Uploadcare::Resources::DocumentConversion.status(
          token: token, client: client, request_options: request_options
        )
      end

      def info(uuid:, request_options: {})
        Uploadcare::Resources::DocumentConversion.info_for(
          uuid: uuid, client: client, request_options: request_options
        )
      end
    end
  end
end
