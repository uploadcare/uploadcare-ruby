# frozen_string_literal: true

module Uploadcare
  module Entity
    # This serializer returns a single file
    #
    # https://uploadcare.com/docs/api_reference/rest/handling_projects/
    class File < ApiStruct::Entity # @api
      client_service FileClient

      attr_entity :datetime_removed, :datetime_stored, :datetime_uploaded, :image_info, :is_image, :is_ready,
                  :mime_type, :original_file_url, :original_filename, :size, :url, :uuid

      # 'copy' method is used to copy original files or their modified versions to default storage.
      #
      # Source files MAY either be stored or just uploaded and MUST NOT be deleted.
      #
      # @param [String] source uuid or uploadcare link to file.
      # @param [Hash] args
      # @option args [Boolean] :store Whether to store the file
      # @option args [Boolean] :strip_operations Copies file without transformations (if source has them)
      # @option args [String] :target points to a target custom storage.
      # @option args [Boolean] :make_public make files on custom storage available via public links.
      # @option args [String] :pattern define file naming pattern for the custom storage scenario.
      #
      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/copyFile

      def self.copy(source, **args)
        response = FileClient.new.copy(source: source, **args).success[:result]
        File.new(response)
      end

      # Copies file to current project
      #
      # source can be UID or full CDN link
      #
      # @see .copy

      def self.internal_copy(source, **args)
        File.copy(source, **args)
      end

      # copy file to different project
      #
      # source can be UID or full CDN link
      #
      # @see .copy

      def self.external_copy(source, target, **args)
        File.copy(source: source, target: target, **args)
      end

      # Instance version of #{copy}. Copies current file.

      def copy(**args)
        File.copy(uuid, **args)
      end

      # Instance version of {internal_copy}

      def internal_copy(**args)
        File.internal_copy(uuid, **args)
      end

      # Instance version of {external_copy}

      def external_copy(target, **args)
        File.copy(uuid, target: target, **args)
      end
    end
  end
end
