# frozen_string_literal: true
require 'retries'

module Uploadcare
  # This is client for general uploads
  # https://uploadcare.com/api-refs/upload-api/#tag/Upload
  class UploadClient < ApiStruct::Client
    upload_api

    # https://uploadcare.com/api-refs/upload-api/#operation/baseUpload

    def upload_many(arr, **options)
      body = HTTP::FormData::Multipart.new(
        Upload::UploadParamsGenerator.call(options[:store]).merge(files_formdata(arr))
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
    # https://uploadcare.com/api-refs/upload-api/#operation/fromURLUpload
    # options:
    # - check_URL_duplicates
    # - filename
    # - save_URL_duplicates
    # - async - returns upload token instead of upload data

    def upload_from_url(url, **options)
      body = HTTP::FormData::Multipart.new({
        'pub_key': PUBLIC_KEY,
        'source_url': url
      }.merge(options))
      token_response = post(path: 'from_url/', headers: { 'Content-type': body.content_type }, body: body)
      return token_response if options[:async]

      uploaded_response = poll_upload_response(token_response.success[:token])
      return uploaded_response if uploaded_response.success[:status] == 'error'

      Dry::Monads::Success(files: [uploaded_response.success])
    end

    private

    def poll_upload_response(token)
      with_retries(max_tries: MAX_REQUEST_TRIES, base_sleep_seconds: BASE_REQUEST_SLEEP_SECONDS,
                   max_sleep_seconds: MAX_REQUEST_SLEEP_SECONDS) do
        response = get_status_response(token)
        raise RequestError if %w[progress waiting unknown].include?(response.success[:status])
        response
      end
    end

    def get_status_response(token)
      query_params = { token: token }
      get(path: 'from_url/status/', params: query_params)
    end

    def files_formdata(arr)
      arr.map do |file|
        [HTTP::FormData::File.new(file).filename,
         HTTP::FormData::File.new(file)]
      end .to_h
    end

    def upload_params(store = 'auto')
      store = '1' if store == true
      store = '0' if store == false
      {
        'UPLOADCARE_PUB_KEY': PUBLIC_KEY,
        'UPLOADCARE_STORE': store
      }
    end

    def file?(object)
      object.respond_to?(:path) && ::File.exist?(object.path)
    end
  end
end
