require 'json'

require 'uploadcare/api/connections'

module Uploadcare
  module RawApi

    def initialize options={}
      @options = Uploadcare::default_settings.merge(options)  
    end


    # basic request method 
    def request method = :get, path = "/files/", params = {}
      response = send_request(method, path, params)
      parse(response)
    end
    alias_method :api_request, :request


    # request with GET verb
    def get path= "/files/", params={}
      request :get, path, params
    end


    # request with POST verb
    def post path= "/files/", params={}
      request :post, path, params 
    end

    # request with PUT verb
    def put path= "/files/", params={}
      request :put, path, params
    end


    # request with DELETE verb
    def delete path= "/files/", params={}
      request :delete, path, params
    end


    protected
      def send_request method, path, params={}
        connection = Uploadcare::Connections::ApiConnection.new @options
        response = connection.send method, path, params
      end


      def parse response
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
  end
end