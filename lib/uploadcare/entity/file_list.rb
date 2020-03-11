# frozen_string_literal: true

require 'uploadcare/entity/file'

module Uploadcare
  module Entity
    # This serializer returns lists of files
    class FileList < Entity
      client_service FileListClient

      attr_entity :next, :previous, :total, :per_page

      has_entities :results, as: File
      has_entities :result, as: Uploadcare::Entity::File

      def files
        result || results
      end
    end
  end
end
