# frozen_string_literal: true

require 'retries'

module Uploadcare
  module Client
    # This is client for general uploads
    #
    # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload
    class UploadClient < ApiStruct::Client
      include Concerns::ErrorHandler
      include Concerns::ThrottleHandler
      include Exception
      upload_api

      # @see https://uploadcare.com/api-refs/upload-api/#operation/baseUpload

      def upload_many(arr, **options)
        body = HTTP::FormData::Multipart.new(
          Param::Upload::UploadParamsGenerator.call(options[:store]).merge(files_formdata(arr))
        )
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
        body = HTTP::FormData::Multipart.new({
          'pub_key': Uploadcare.configuration.public_key,
          'source_url': url
        }.merge(options))
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
        with_retries(max_tries: Uploadcare.configuration.max_request_tries,
                     base_sleep_seconds: Uploadcare.configuration.base_request_sleep_seconds,
                     max_sleep_seconds: Uploadcare.configuration.max_request_sleep_seconds) do
          response = get_status_response(token)
          raise RequestError if %w[progress waiting unknown].include?(response.success[:status])
          response
        end
      end

      # Check upload status

      def get_status_response(token)
        query_params = { token: token }
        get(path: 'from_url/status/', params: query_params)
      end

      # Convert

      def files_formdata(arr)
        arr.map do |file|
          [HTTP::FormData::File.new(file).filename,
           HTTP::FormData::File.new(file)]
        end .to_h
      end
    end
  end
end
