# frozen_string_literal: true

# Resource representing lists of files -
# both as collection and as a paginated list of files with info about whole collection

require 'uploadcare/entity/file'

module Uploadcare
  class FileList < ApiStruct::Entity
    client_service FileListClient

    attr_entity :next, :previous, :total, :per_page, :results, :result, :files
    has_entities :files, as: Uploadcare::File
  end
end
