# frozen_string_literal: true

module Uploadcare
  class UploadClient
    BASE_URL = 'https://upload.uploadcare.com'

    def initialize(config = Uploadcare.configuration)
      @config = config
    end

    private

    attr_reader :config

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |faraday|
        faraday.request :multipart
        faraday.request :url_encoded
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
      end
    end

    def execute_request(method, uri, params = {}, headers = {})
      params[:pub_key] = config.public_key
      headers['User-Agent'] = user_agent

      response = connection.send(method, uri, params, headers)
      
      handle_response(response)
    rescue Faraday::Error => e
      handle_faraday_error(e)
    end

    def handle_response(response)
      if response.success?
        response.body
      else
        raise_upload_error(response)
      end
    end

    def handle_faraday_error(error)
      message = error.message
      raise Uploadcare::RequestError, "Request failed: #{message}"
    end

    def raise_upload_error(response)
      body = response.body
      error_message = if body.is_a?(Hash)
                        body['error'] || body['detail'] || "Upload failed"
                      else
                        "Upload failed with status #{response.status}"
                      end
      
      raise Uploadcare::RequestError.new(error_message, response.status)
    end

    def user_agent
      "Uploadcare Ruby/#{Uploadcare::VERSION} (Ruby/#{RUBY_VERSION})"
    end
  end
end