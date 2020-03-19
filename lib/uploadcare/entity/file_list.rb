# frozen_string_literal: true

require 'uploadcare/entity/file'
require 'uploadcare/entity/decorator/paginator'

module Uploadcare
  module Entity
    # This serializer returns lists of files
    #
    # This is a paginated list, so all pagination methods apply
    # @see Uploadcare::Entity::Decorator::Paginator
    class FileList < ApiStruct::Entity
      include Uploadcare::Entity::Decorator::Paginator
      client_service Client::FileListClient

      attr_entity :next, :previous, :total, :per_page

      has_entities :results, as: Uploadcare::Entity::File
      has_entities :result, as: Uploadcare::Entity::File

      # alias for result/results, depending on which API this FileList was initialized from
      # @return [Array] of [Uploadcare::Entity::File]
      def files
        results
      rescue ApiStruct::EntityError
        result
      end
    end
  end
end
