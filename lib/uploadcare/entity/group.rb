# frozen_string_literal: true

require 'uploadcare/entity/file'

module Uploadcare
  module Entity
    # Groups serve a purpose of better organizing files in your Uploadcare projects.
    #
    # You can create one from a set of files by using their UUIDs.
    #
    # @see https://uploadcare.com/docs/api_reference/upload/groups/
    class Group < Entity
      client_service RestGroupClient, prefix: 'rest', only: :store
      client_service GroupClient

      attr_entity :id, :datetime_created, :datetime_stored, :files_count, :cdn_url, :url
      has_entities :files, as: Uploadcare::Entity::File

      # Remove these lines and bump api_struct version when this PR is accepted:
      # @see https://github.com/rubygarage/api_struct/pull/15

      def self.store(uuid)
        rest_store(uuid)
      end

      # gets groups's id - even if it's only initialized with cdn_url
      # @return [String]

      def id
        return @entity.id if @entity.id

        id = @entity.cdn_url.gsub('https://ucarecdn.com/', '')
        id = id.gsub(%r{\/.*}, '')
        id
      end

      # loads group metadata, if it's initialized with url or id

      def load
        initialize(Group.info(id).entity)
      end
    end
  end
end
