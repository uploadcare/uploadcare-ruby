# frozen_string_literal: true

require 'uploadcare/entity/group'
require 'uploadcare/entity/decorator/paginator'

module Uploadcare
  module Entity
    # List of groups
    #
    # @see https://uploadcare.com/docs/api_reference/upload/groups/
    #
    # This is a paginated list, so all pagination methods apply
    # @see Uploadcare::Entity::Decorator::Paginator
    class GroupList < Entity
      include Uploadcare::Entity::Decorator::Paginator
      client_service RestGroupClient, only: :list

      attr_entity :next, :previous, :total, :per_page, :results
      has_entities :results, as: Group

      alias groups results
    end
  end
end
