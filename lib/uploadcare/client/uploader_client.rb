# frozen_string_literal: true

require_relative 'upload_client'
require 'retries'
require 'param/upload/upload_params_generator'

module Uploadcare
  module Client
    # This is client for general uploads
    #
    # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload
    class UploaderClient < UploadClient
      # @see https://uploadcare.com/api-refs/upload-api/#operation/baseUpload

      def upload_many(arr, options = {})
        body = upload_many_body(arr, options)
        post(path: 'base/',
             headers: { 'Content-Type': body.content_type },
             body: body)
      end

      # syntactic sugar for upload_many
      # There is actual upload method for one file, but it is redundant

      def upload(file, options = {})
        upload_many([file], options)
      end

      # Upload files from url
      # @see https://uploadcare.com/api-refs/upload-api/#operation/fromURLUpload
      # options:
      # - check_URL_duplicates
      # - filename
      # - save_URL_duplicates
      # - async - returns upload token instead of upload data
      # - metadata - file metadata, hash
      def upload_from_url(url, options = {})
        body = upload_from_url_body(url, options)
        token_response = post(path: 'from_url/', headers: { 'Content-Type': body.content_type }, body: body)
        return token_response if options[:async]

        uploaded_response = poll_upload_response(token_response.success[:token])
        return uploaded_response if uploaded_response.success[:status] == 'error'

        Dry::Monads::Result::Success.call(files: [uploaded_response.success])
      end

      # Check upload status
      #
      # @see https://uploadcare.com/api-refs/upload-api/#operation/fromURLUploadStatus
      def get_upload_from_url_status(token)
        query_params = { token: token }
        get(path: 'from_url/status/', params: query_params)
      end

      # Get information about an uploaded file
      # Secret key not needed
      #
      # https://uploadcare.com/api-refs/upload-api/#tag/Upload/operation/fileUploadInfo
      def file_info(uuid)
        query_params = {
          file_id: uuid,
          pub_key: Uploadcare.config.public_key
        }
        get(path: 'info/', params: query_params)
      end

      private

      alias api_struct_post post
      def post(args = {})
        handle_throttling { api_struct_post(**args) }
      end

      def poll_upload_response(token)
        with_retries(max_tries: Uploadcare.config.max_request_tries,
                     base_sleep_seconds: Uploadcare.config.base_request_sleep,
                     max_sleep_seconds: Uploadcare.config.max_request_sleep) do
          response = get_upload_from_url_status(token)

          if %w[progress waiting unknown].include?(response.success[:status])
            raise RequestError, 'Upload is taking longer than expected. Try increasing the max_request_tries config if you know your file uploads will take more time.' # rubocop:disable Layout/LineLength
          end

          response
        end
      end

      # Prepares body for upload_many method
      def upload_many_body(arr, options = {})
        files_formdata = arr.to_h do |file|
          [HTTP::FormData::File.new(file).filename,
           form_data_for(file)]
        end
        HTTP::FormData::Multipart.new(
          Param::Upload::UploadParamsGenerator.call(options).merge(files_formdata)
        )
      end

      # Prepare upload_from_url initial request body
      def upload_from_url_body(url, options = {})
        HTTP::FormData::Multipart.new(
          options.merge(
            'pub_key' => Uploadcare.config.public_key,
            'source_url' => url,
            'store' => store_value(options[:store])
          )
        )
      end

      def store_value(store)
        case store
        when true, '1', 1 then '1'
        when false, '0', 0 then '0'
        else 'auto'
        end
      end
    end
  end
end
