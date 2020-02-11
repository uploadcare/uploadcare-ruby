# frozen_string_literal: true

require 'uploadcare/entity/file'

module Uploadcare
  # Resource representing lists of files
  class FileList < ApiStruct::Entity
    client_service FileListClient

    attr_entity :next, :previous, :total, :per_page

    has_entities :results, as: Uploadcare::File
    has_entities :result, as: Uploadcare::File

    def files
      result || results
    end
  end
end
