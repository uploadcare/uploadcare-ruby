require 'faraday'
require 'faraday_middleware'
require 'json'
require 'ostruct'

module Uploadcare
  class RawApi
    attr_reader :options

    def request method = :get, path = "/files/", params = {}
      connection = Faraday.new url: @options[:api_url_base] do |frd|
        frd.request :url_encoded
        frd.use FaradayMiddleware::FollowRedirects, limit: 3
        frd.adapter :net_http # actually, default adapter, just to be clear
        frd.headers['Authorization'] = "Uploadcare.Simple #{@options[:public_key]}:#{@options[:private_key]}"
        frd.headers['Accept'] = "application/vnd.uploadcare-v#{@options[:api_version]}+json"
        frd.headers['User-Agent'] = Uploadcare::user_agent
      end 

      # get the response
      response = connection.send method, path, params

      # and try to get actual data
      # 404 code return in html instead of JSON, so - safety wrapper
      begin
        object = JSON.parse(response.body)
      rescue JSON::ParserError
        object = false
      end

      # and returning the object (file actually) or raise new error
      if response.status < 300
        object
      else
        message = "HTTP code #{response.status}"
        if object # add active_support god damn it
          message += ": #{object["detail"]}"
        else
          message += ": unknown error occured."
        end

        raise ArgumentError.new(message)
      end
    end
    alias_method :api_request, :request
  end
end