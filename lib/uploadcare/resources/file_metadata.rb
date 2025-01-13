# frozen_string_literal: true

module Uploadcare
  class FileMetadata < BaseResource
    ATTRIBUTES = %i[
      datetime_removed datetime_stored datetime_uploaded is_image is_ready mime_type original_file_url
      original_filename size url uuid variations content_info metadata appdata source
    ].freeze

    attr_accessor(*ATTRIBUTES)

    def initialize(attributes = {}, config = Uploadcare.configuration)
      super
      @file_metadata_client = Uploadcare::FileMetadataClient.new(config)
    end

    # Retrieves metadata for the file
    # @return [Hash] The metadata keys and values for the file
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/_fileMetadata
    # TODO - Remove uuid if the opeartion is being perfomed on same file
    def index(uuid)
      response = @file_metadata_client.index(uuid)
      assign_attributes(response)
      self
    end

    # Updates metadata key's value
    # @return [String] The updated value of the metadata key
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/updateFileMetadataKey
    # TODO - Remove uuid if the opeartion is being perfomed on same file
    def update(uuid, key, value)
      @file_metadata_client.update(uuid, key, value)
    end

    # Retrieves the value of a specific metadata key for the file
    # @param key [String] The metadata key to retrieve
    # @return [String] The value of the metadata key
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/fileMetadata
    # TODO - Remove uuid if the opeartion is being perfomed on same file
    def show(uuid, key)
      @file_metadata_client.show(uuid, key)
    end

    # Deletes a specific metadata key for the file
    # @param key [String] The metadata key to delete
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/deleteFileMetadata
    # TODO - Remove uuid if the opeartion is being perfomed on same file
    def delete(uuid, key)
      @file_metadata_client.delete(uuid, key)
    end
  end
end
