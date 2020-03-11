# frozen_string_literal: true

require 'uploadcare/entity/group'

module Uploadcare
  module Entity
    # List of groups
    #
    # @see https://uploadcare.com/docs/api_reference/upload/groups/
    class GroupList < Entity
      client_service RestGroupClient, only: :list

      attr_entity :next, :previous, :total, :per_page, :results
      has_entities :results, as: Group

      alias groups results
    end
  end
end
