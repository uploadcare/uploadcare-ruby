# frozen_string_literal: true

module Uploadcare
  # Helper methods for multipart upload operations
  module MultipartUploadHelpers
    private

    # Generate upload parameters (integrated from UploadParamsGenerator)
    # @param options [Hash] upload options
    # @return [Hash] parameters for upload API
    def generate_upload_params(options = {})
      params = {
        'UPLOADCARE_PUB_KEY' => Uploadcare.configuration.public_key,
        'UPLOADCARE_STORE' => store_value(options[:store])
      }

      # Add signature if uploads are signed
      if Uploadcare.configuration.sign_uploads
        signature = generate_upload_signature
        params['signature'] = signature if signature
      end

      # Add metadata if provided
      params.merge!(generate_metadata_params(options[:metadata]))

      # Remove nil values
      params.compact
    end

    # Generate upload signature if signing is enabled
    # @return [String, nil] upload signature or nil if not available
    def generate_upload_signature
      # Check if SignatureGenerator is available
      if defined?(Uploadcare::Param::Upload::SignatureGenerator)
        Uploadcare::Param::Upload::SignatureGenerator.call
      else
        # Log warning that signing is enabled but generator is not available
        Uploadcare.configuration.logger&.warn('Upload signing is enabled but SignatureGenerator is not available')
        nil
      end
    rescue StandardError => e
      # Log error and continue without signature
      Uploadcare.configuration.logger&.error("Failed to generate upload signature: #{e.message}")
      nil
    end

    # Extract file parameters for multipart form
    def multipart_file_params(file)
      filename = file.respond_to?(:original_filename) ? file.original_filename : ::File.basename(file.path)
      mime_type = MIME::Types.type_for(file.path).first
      content_type = mime_type ? mime_type.content_type : 'application/octet-stream'

      {
        'filename' => filename,
        'size' => file.size.to_s,
        'content_type' => content_type
      }
    end

    # Build multipart form parameters for upload start
    def multipart_start_params(object, options)
      # Generate upload parameters
      upload_params = generate_upload_params(options)

      # Merge with file form data
      file_params = multipart_file_params(object)

      upload_params.merge(file_params)
    end

    # Convert store option to API-compatible value
    def store_value(store)
      return 'auto' if store.nil?

      case store
      when true, 1, '1'
        'true'
      when false, 0, '0'
        'false'
      else
        store.to_s
      end
    end

    # Generate metadata parameters for upload
    def generate_metadata_params(metadata = nil)
      return {} if metadata.nil? || !metadata.is_a?(Hash)

      metadata.each_with_object({}) do |(key, value), result|
        result["metadata[#{key}]"] = value.to_s
      end
    end
  end
end
