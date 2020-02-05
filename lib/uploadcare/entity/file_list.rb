# frozen_string_literal: true

require 'uploadcare/entity/file'

module Uploadcare
  # Resource representing lists of files
  class FileList < ApiStruct::Entity
    client_service FileListClient

    attr_entity :next, :previous, :total, :per_page, :results, :result, :files
    has_entities :files, as: Uploadcare::File
  end
end
