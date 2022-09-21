# frozen_string_literal: true

module Uploadcare
  module Entity
    # This serializer is responsible for file metadata handling
    #
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata
    class FileMetadata < Entity
      client_service FileMetadataClient

      class << self
        def index(uuid)
          ::Uploadcare::Client::FileMetadataClient.new.index(uuid).success
        end

        def show(uuid, key)
          ::Uploadcare::Client::FileMetadataClient.new.show(uuid, key).success
        end

        def update(uuid, key, value)
          ::Uploadcare::Client::FileMetadataClient.new.update(uuid, key, value).success
        end

        def delete(uuid, key)
          '200 OK' if ::Uploadcare::Client::FileMetadataClient.new.delete(uuid, key).success?
        end
      end
    end
  end
end
