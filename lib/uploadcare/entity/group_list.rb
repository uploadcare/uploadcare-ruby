# frozen_string_literal: true

require 'uploadcare/entity/group'

module Uploadcare
  # List of groups
  # https://uploadcare.com/docs/api_reference/upload/groups/
  class GroupList < ApiStruct::Entity
    client_service RestGroupClient, only: :list

    attr_entity :next, :previous, :total, :per_page, :results
    has_entities :results, as: Uploadcare::Group

    alias groups results
  end
end
