# frozen_string_literal: true

module Uploadcare
  class Client
    class GroupsAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def create(uuids, request_options: {}, **options)
        Uploadcare::Resources::Group.create(
          uuids: uuids, client: client, request_options: request_options, **options
        )
      end

      def find(group_id:, request_options: {})
        Uploadcare::Resources::Group.find(group_id: group_id, client: client, request_options: request_options)
      end

      def list(request_options: {}, **params)
        Uploadcare::Resources::Group.list(params: params, client: client, request_options: request_options)
      end
    end
  end
end
