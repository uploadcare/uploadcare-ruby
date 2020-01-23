# frozen_string_literal: true

# https://uploadcare.com/docs/api_reference/rest/handling_projects/

module Uploadcare
  class Project < ApiStruct::Entity
    client_service ProjectClient

    attr_entity :collaborators, :pub_key, :name, :autostore_enabled
  end
end
