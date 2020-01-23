# frozen_string_literal: true

# Resource for FileList entity - a paginated list of files with info about whole collection
# https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/filesList

module Uploadcare
  class FileList < ApiStruct::Entity
    client_service FileListClient

    attr_entity :next, :previous, :total, :per_page, :results
  end
end
