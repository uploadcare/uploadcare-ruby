# frozen_string_literal: true

module Uploadcare
  class Uploader < BaseResource
    class << self
      # Upload a file or array of files
      # @param input [String, File, Array] File path, File object, or array of files
      # @param options [Hash] Upload options
      # @return [Uploadcare::File, Array<Uploadcare::File>] Uploaded file(s)
      def upload(input, options = {}, config = Uploadcare.configuration)
        case input
        when Array
          upload_files(input, options, config)
        when String
          if input.start_with?('http://', 'https://')
            upload_from_url(input, options, config)
          else
            upload_file(input, options, config)
          end
        else
          upload_file(input, options, config)
        end
      end

      # Upload a single file
      # @param file [String, File] File path or File object
      # @param options [Hash] Upload options
      # @return [Uploadcare::File] Uploaded file
      def upload_file(file, options = {}, config = Uploadcare.configuration)
        uploader_client = UploaderClient.new(config)
        
        file_path = file.is_a?(String) ? file : file.path
        file_size = File.size(file_path)
        
        response = if file_size > 10 * 1024 * 1024 # 10MB threshold for multipart
                     multipart_client = MultipartUploadClient.new(config)
                     multipart_client.upload_file(file_path, options)
                   else
                     uploader_client.upload_file(file_path, options)
                   end
        
        file_data = response['file'] || response
        File.new(file_data, config)
      end

      # Upload multiple files
      # @param files [Array] Array of file paths or File objects
      # @param options [Hash] Upload options
      # @return [Array<Uploadcare::File>] Array of uploaded files
      def upload_files(files, options = {}, config = Uploadcare.configuration)
        files.map { |file| upload_file(file, options, config) }
      end

      # Upload a file from URL
      # @param url [String] URL of the file to upload
      # @param options [Hash] Upload options
      # @return [Uploadcare::File] Uploaded file or token for async upload
      def upload_from_url(url, options = {}, config = Uploadcare.configuration)
        uploader_client = UploaderClient.new(config)
        response = uploader_client.upload_from_url(url, options)
        
        if response['token']
          # Async upload, return token info
          { 
            token: response['token'],
            status: 'pending',
            check_status: -> { check_upload_status(response['token'], config) }
          }
        else
          # Sync upload completed
          file_data = response['file'] || response
          File.new(file_data, config)
        end
      end

      # Check status of async upload
      # @param token [String] Upload token
      # @return [Hash, Uploadcare::File] Status info or uploaded file
      def check_upload_status(token, config = Uploadcare.configuration)
        uploader_client = UploaderClient.new(config)
        response = uploader_client.check_upload_status(token)
        
        case response['status']
        when 'success'
          file_data = response['file'] || response['result']
          File.new(file_data, config)
        when 'error'
          raise Uploadcare::RequestError, response['error'] || 'Upload failed'
        else
          response
        end
      end

      # Get file info without storing
      # @param uuid [String] File UUID
      # @return [Hash] File information
      def file_info(uuid, config = Uploadcare.configuration)
        uploader_client = UploaderClient.new(config)
        uploader_client.file_info(uuid)
      end
    end
  end
end