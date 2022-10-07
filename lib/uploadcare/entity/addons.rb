# frozen_string_literal: true

module Uploadcare
  module Entity
    # This serializer is responsible for addons handling
    #
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons
    class Addons < Entity
      client_service AddonsClient

      attr_entity :request_id, :status, :result
    end
  end
end
