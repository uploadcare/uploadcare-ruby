# frozen_string_literal: true

module Uploadcare
  module Entity
    # This serializer returns info about a project and its data
    # @see https://uploadcare.com/docs/api_reference/rest/handling_projects/
    class Project < Entity
      client_service ProjectClient

      attr_entity :collaborators, :pub_key, :name, :autostore_enabled
    end
  end
end
