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
      client_service RestGroupClient, prefix: 'rest', only: %i[store info delete]
      client_service GroupClient

      attr_entity :id, :datetime_created, :datetime_stored, :files_count, :cdn_url, :url, :file_cdn_urls
      has_entities :files, as: Uploadcare::Entity::File

      # Remove these lines and bump api_struct version when this PR is accepted:
      # @see https://github.com/rubygarage/api_struct/pull/15
      def self.store(uuid)
        rest_store(uuid).success || '200 OK'
      end

      # Get a file group by its ID.
      def self.group_info(uuid)
        rest_info(uuid)
      end

      def self.delete(uuid)
        rest_delete(uuid).success || '200 OK'
      end

      # gets groups's id - even if it's only initialized with cdn_url
      # @return [String]
      def id
        return @entity.id if @entity.id

        id = @entity.cdn_url.gsub('https://ucarecdn.com/', '')
        id.gsub(%r{/.*}, '')
      end

      # loads group metadata, if it's initialized with url or id
      def load
        initialize(Group.info(id).entity)
      end

      # Returns group's CDN URL
      def cdn_url
        "#{Uploadcare.config.cdn_base.call}#{id}/"
      end

      # Returns CDN URLs of all files from group without API requesting
      def file_cdn_urls
        file_cdn_urls = []
        (0...files.count).each do |file_index|
          file_cdn_url = "#{cdn_url}nth/#{file_index}/"
          file_cdn_urls << file_cdn_url
        end
        file_cdn_urls
      end
    end
  end
end
