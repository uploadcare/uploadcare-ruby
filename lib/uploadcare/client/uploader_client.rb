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

      def upload_many(arr, **options)
        body = upload_many_body(arr, **options)
        post(path: 'base/',
             headers: { 'Content-type': body.content_type },
             body: body)
      end

      # syntactic sugar for upload_many
      # There is actual upload method for one file, but it is redundant

      def upload(file, **options)
        upload_many([file], **options)
      end

      # Upload files from url
      # @see https://uploadcare.com/api-refs/upload-api/#operation/fromURLUpload
      # options:
      # - check_URL_duplicates
      # - filename
      # - save_URL_duplicates
      # - async - returns upload token instead of upload data
      def upload_from_url(url, **options)
        body = upload_from_url_body(url, **options)
        token_response = post(path: 'from_url/', headers: { 'Content-type': body.content_type }, body: body)
        return token_response if options[:async]

        uploaded_response = poll_upload_response(token_response.success[:token])
        return uploaded_response if uploaded_response.success[:status] == 'error'

        Dry::Monads::Success(files: [uploaded_response.success])
      end

      private

      alias api_struct_post post
      def post(**args)
        handle_throttling { api_struct_post(**args) }
      end

      def poll_upload_response(token)
        with_retries(max_tries: Uploadcare.config.max_request_tries,
                     base_sleep_seconds: Uploadcare.config.base_request_sleep,
                     max_sleep_seconds: Uploadcare.config.max_request_sleep) do
          response = get_status_response(token)
          raise RequestError if %w[progress waiting unknown].include?(response.success[:status])

          response
        end
      end

      # Check upload status
      #
      # @see https://uploadcare.com/api-refs/upload-api/#operation/fromURLUploadStatus
      def get_status_response(token)
        query_params = { token: token }
        get(path: 'from_url/status/', params: query_params)
      end

      # Prepares body for upload_many method
      def upload_many_body(arr, **options)
        files_formdata = arr.map do |file|
          [HTTP::FormData::File.new(file).filename,
           HTTP::FormData::File.new(file)]
        end .to_h
        HTTP::FormData::Multipart.new(
          Param::Upload::UploadParamsGenerator.call(options[:store]).merge(files_formdata)
        )
      end

      # Prepare upload_from_url initial request body
      def upload_from_url_body(url, **options)
        HTTP::FormData::Multipart.new({
          'pub_key': Uploadcare.config.public_key,
          'source_url': url
        }.merge(**options))
      end
    end
  end
end
