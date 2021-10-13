# frozen_string_literal: true

module Uploadcare
  module Entity
    # This serializer returns a single file
    #
    # @see https://uploadcare.com/docs/api_reference/rest/handling_projects/
    class File < Entity
      client_service FileClient

      attr_entity :datetime_removed, :datetime_stored, :datetime_uploaded, :image_info, :is_image, :is_ready,
                  :mime_type, :original_file_url, :original_filename, :size, :url, :uuid, :variations, :video_info,
                  :source, :rekognition_info

      # gets file's uuid - even if it's only initialized with url
      # @returns [String]
      def uuid
        return @entity.uuid if @entity.uuid

        uuid = @entity.url.gsub('https://ucarecdn.com/', '')
        uuid.gsub(%r{/.*}, '')
      end

      # loads file metadata, if it's initialized with url or uuid
      def load
        initialize(File.info(uuid).entity)
      end

      # The method to convert a document file to another file
      # gets (conversion) params [Hash], options (store: Boolean) [Hash], converter [Class]
      # @returns [File]
      def convert_document(params = {}, options = {}, converter = Conversion::DocumentConverter)
        convert_file(params, converter, options)
      end

      # The method to convert a video file to another file
      # gets (conversion) params [Hash], options (store: Boolean) [Hash], converter [Class]
      # @returns [File]
      def convert_video(params = {}, options = {}, converter = Conversion::VideoConverter)
        convert_file(params, converter, options)
      end

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
      def self.local_copy(source, **args)
        File.copy(source, **args)
      end

      # copy file to different project
      #
      # source can be UID or full CDN link
      #
      # @see .copy
      def self.remote_copy(source, target, **args)
        File.copy(source: source, target: target, **args)
      end

      # Instance version of #{copy}. Copies current file.
      def copy(**args)
        File.copy(uuid, **args)
      end

      # Instance version of {internal_copy}
      def local_copy(**args)
        File.local_copy(uuid, **args)
      end

      # Instance version of {external_copy}
      def remote_copy(target, **args)
        File.copy(uuid, target: target, **args)
      end

      # Store a single file, preventing it from being deleted in 2 weeks
      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/storeFile
      def store
        File.store(uuid)
      end

      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/deleteFile
      def delete
        File.delete(uuid)
      end

      private

      def convert_file(params, converter, options = {})
        raise Uploadcare::Exception::ConversionError, 'The first argument must be a Hash' unless params.is_a?(Hash)

        params_with_symbolized_keys = params.map { |k, v| [k.to_sym, v] }.to_h
        params_with_symbolized_keys[:uuid] = uuid
        result = converter.convert(params_with_symbolized_keys, options)
        result.success? ? File.info(result.value![:result].first[:uuid]) : result
      end
    end
  end
end
