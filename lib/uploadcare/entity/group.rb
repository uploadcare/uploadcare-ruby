# frozen_string_literal: true

require 'uploadcare/entity/file'

module Uploadcare
  # Groups serve a purpose of better organizing files in your Uploadcare projects.
  # You can create one from a set of files by using their UUIDs.
  # https://uploadcare.com/docs/api_reference/upload/groups/
  class Group < ApiStruct::Entity
    client_service RestGroupClient, prefix: 'rest', only: :store
    client_service GroupClient

    attr_entity :id, :datetime_created, :datetime_stored, :files_count, :cdn_url, :url
    has_entities :files, as: Uploadcare::Entity::File

    # Remove these lines and bump api_struct version when this PR is accepted:
    # https://github.com/rubygarage/api_struct/pull/15

    def self.store(uuid)
      rest_store(uuid)
    end
  end
end
