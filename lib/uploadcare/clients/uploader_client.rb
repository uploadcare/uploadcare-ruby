# frozen_string_literal: true

require_relative 'upload_client'
require 'faraday'
require 'digest'

module Uploadcare
  class UploaderClient < UploadClient
    def upload_many(array_of_files, options = {})
      upload_params = build_upload_params(array_of_files, options)
      post('/base/', upload_params)
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
      token_response = post('/from_url/', body)
      return token_response if options[:async]

      uploaded_response = poll_upload_response(token_response['token'])
      return uploaded_response if uploaded_response['status'] == 'error'

      uploaded_response
    end

    # Prepare upload_from_url parameters for Faraday
    def upload_from_url_body(url, options = {})
      {
        'pub_key' => Uploadcare.configuration.public_key,
        'source_url' => url,
        'store' => store_value(options[:store])
      }
      # opts.merge!(Param::Upload::SignatureGenerator.call) if Uploadcare.config.sign_uploads
      # options.merge(opts)
    end

    # Check upload status (public method)
    #
    # @see https://uploadcare.com/api-refs/upload-api/#operation/fromURLUploadStatus
    def get_upload_from_url_status(token)
      fetch_upload_from_url_status(token)
    end

    # Check upload status (internal method)
    #
    # @see https://uploadcare.com/api-refs/upload-api/#operation/fromURLUploadStatus
    def fetch_upload_from_url_status(token)
      get('from_url/status/', { token: token })
    end

    def file_info(uuid)
      get('info/', { file_id: uuid, pub_key: Uploadcare.configuration.public_key })
    end

    private

    # Prepares parameters for upload_many method using Faraday's multipart
    def build_upload_params(files, options = {})
      params = upload_options_to_params(options)

      files.each do |file|
        params = form_data_for(file, params)
      end

      params
    end

    # Convert upload options to API parameters
    def upload_options_to_params(options)
      params = { 'UPLOADCARE_PUB_KEY' => @config.public_key }
      params['UPLOADCARE_STORE'] = store_value(options[:store]) if options[:store]
      params.merge!(generate_metadata_params(options[:metadata]))
      params
    end

    def poll_upload_response(token)
      max_tries = Uploadcare.configuration.max_request_tries
      base_sleep = Uploadcare.configuration.base_request_sleep
      max_sleep = Uploadcare.configuration.max_request_sleep

      tries = 0
      begin
        tries += 1
        response = fetch_upload_from_url_status(token)

        handle_polling_response(response)
      rescue RetryError => e
        raise e unless tries < max_tries

        # Exponential backoff with jitter
        sleep_time = [base_sleep * (2**(tries - 1)), max_sleep].min
        sleep(sleep_time)
        retry
      end
    end

    def handle_polling_response(response)
      case response['status']
      when 'error'
        raise RequestError, response['error']
      when 'progress', 'waiting', 'unknown'
        raise RetryError, response['error'] || 'Upload is taking longer than expected. Try increasing the max_request_tries config if you know your file uploads will take more time.' # rubocop:disable Layout/LineLength
      end

      response
    end
  end
end
