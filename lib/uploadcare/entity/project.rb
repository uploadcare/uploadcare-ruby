# frozen_string_literal: true

module Uploadcare
  # resource representing projects
  # https://uploadcare.com/docs/api_reference/rest/handling_projects/
  class Project < ApiStruct::Entity
    client_service ProjectClient

    attr_entity :collaborators, :pub_key, :name, :autostore_enabled
  end
end
