# frozen_string_literal: true

module Uploadcare
  module Entity
    # This serializer returns a single file
    #
    # @see https://uploadcare.com/docs/api_reference/rest/handling_projects/
    class File < Entity
      RESPONSE_PARAMS = %i[
        datetime_removed datetime_stored datetime_uploaded is_image is_ready mime_type original_file_url
        original_filename size url uuid variations content_info metadata appdata source
      ].freeze

      client_service FileClient

      attr_entity(*RESPONSE_PARAMS)

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

      # Copies file to current project
      #
      # source can be UID or full CDN link
      #
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/createLocalCopy
      def self.local_copy(source, args = {})
        response = FileClient.new.local_copy(source: source, **args).success[:result]
        File.new(response)
      end

      # copy file to different project
      #
      # source can be UID or full CDN link
      #
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File/operation/createRemoteCopy
      def self.remote_copy(source, target, args = {})
        response = FileClient.new.remote_copy(source: source, target: target, **args).success[:result]
        File.new(response)
      end

      # Instance version of {internal_copy}
      def local_copy(args = {})
        File.local_copy(uuid, **args)
      end

      # Instance version of {external_copy}
      def remote_copy(target, args = {})
        File.remote_copy(uuid, target, **args)
      end

      # Store a single file, preventing it from being deleted in 2 weeks
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/storeFile
      def store
        File.store(uuid)
      end

      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/deleteFileStorage
      def delete
        File.delete(uuid)
      end

      private

      def convert_file(params, converter, options = {})
        raise Uploadcare::Exception::ConversionError, 'The first argument must be a Hash' unless params.is_a?(Hash)

        params_with_symbolized_keys = params.to_h { |k, v| [k.to_sym, v] }
        params_with_symbolized_keys[:uuid] = uuid
        result = converter.convert(params_with_symbolized_keys, options)
        result.success? ? File.info(result.value![:result].first[:uuid]) : result
      end
    end
  end
end
