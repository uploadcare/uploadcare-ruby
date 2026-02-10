# frozen_string_literal: true

require_relative 'upload_client'
require 'faraday'
require 'digest'

# Client for upload endpoints.
class Uploadcare::UploaderClient < Uploadcare::UploadClient
  # Upload multiple files in a single request.
  #
  # @param files [Array<File>] files to upload
  # @param options [Hash] upload options
  # @return [Uploadcare::Result]
  def upload_many(files:, request_options: {}, **options)
    Uploadcare::Result.capture do
      upload_params = build_upload_params(files, options)
      Uploadcare::Result.unwrap(post(path: '/base/', params: upload_params, request_options: request_options))
    end
  end

  # syntactic sugar for upload_many
  # There is actual upload method for one file, but it is redundant
  # Upload a single file.
  #
  # @param file [File] file to upload
  # @param options [Hash] upload options
  # @return [Uploadcare::Result]
  def upload(file:, request_options: {}, **options)
    upload_many(files: [file], request_options: request_options, **options)
  end

  # Upload files from url
  # @see https://uploadcare.com/api-refs/upload-api/#operation/fromURLUpload
  # options:
  # - check_URL_duplicates
  # - filename
  # - save_URL_duplicates
  # - async - returns upload token instead of upload data
  # - metadata - file metadata, hash
  # Upload a file from URL.
  #
  # @param url [String] source URL
  # @param options [Hash] upload options
  # @return [Uploadcare::Result]
  def upload_from_url(url:, request_options: {}, **options)
    Uploadcare::Result.capture do
      body = upload_from_url_body(url: url, **options)
      token_response = Uploadcare::Result.unwrap(post(path: '/from_url/', params: body,
                                                      request_options: request_options))
      return token_response if options[:async]

      uploaded_response = poll_upload_response(token: token_response['token'], options: options,
                                               request_options: request_options)
      return uploaded_response if uploaded_response['status'] == 'error'

      uploaded_response
    end
  end

  # Prepare upload_from_url parameters for Faraday
  def upload_from_url_body(url:, **options)
    params = {
      'pub_key' => config.public_key,
      'source_url' => url,
      'store' => store_value(options[:store])
    }
    params.merge!(signature_params(options))
    params
  end

  # Check upload status (public method)
  #
  # @see https://uploadcare.com/api-refs/upload-api/#operation/fromURLUploadStatus
  # Fetch upload-from-URL status.
  #
  # @param token [String] upload token
  # @return [Uploadcare::Result]
  def get_upload_from_url_status(token:, request_options: {})
    upload_from_url_status(token: token, request_options: request_options)
  end

  # Fetch upload-from-URL status and wrap in Result.
  #
  # @param token [String] upload token
  # @return [Uploadcare::Result]
  def upload_from_url_status(token:, request_options: {})
    Uploadcare::Result.capture do
      Uploadcare::Result.unwrap(fetch_upload_from_url_status(token: token, request_options: request_options))
    end
  end

  # Check upload status (internal method)
  #
  # @see https://uploadcare.com/api-refs/upload-api/#operation/fromURLUploadStatus
  def fetch_upload_from_url_status(token:, request_options: {})
    get(path: 'from_url/status/', params: { token: token }, request_options: request_options)
  end

  # Fetch file info from Upload API.
  #
  # @param uuid [String] file UUID
  # @return [Hash]
  def file_info(uuid:, request_options: {})
    get(path: 'info/', params: { file_id: uuid, pub_key: config.public_key }, request_options: request_options)
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
    if options.key?(:store)
      store = store_value(options[:store])
      params['UPLOADCARE_STORE'] = store unless store.nil?
    end
    params.merge!(generate_metadata_params(options[:metadata]))
    params
  end

  def poll_upload_response(token:, options: {}, request_options: {})
    max_tries = options.fetch(:max_request_tries, config.max_request_tries)
    base_sleep = options.fetch(:base_request_sleep, config.base_request_sleep)
    max_sleep = options.fetch(:max_request_sleep, config.max_request_sleep)

    tries = 0
    begin
      tries += 1
      response = Uploadcare::Result.unwrap(fetch_upload_from_url_status(token: token,
                                                                        request_options: request_options))

      handle_polling_response(response)
    rescue Uploadcare::Exception::RetryError => e
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
      raise Uploadcare::Exception::RequestError, "Upload failed: #{response['error']}"
    when 'progress', 'waiting', 'unknown'
      raise Uploadcare::Exception::RetryError, response['error'] || 'Upload is taking longer than expected. Try increasing the max_request_tries config if you know your file uploads will take more time.' # rubocop:disable Layout/LineLength
    end

    response
  end
end
