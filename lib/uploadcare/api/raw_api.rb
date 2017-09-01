require 'json'

module Uploadcare
  module RawApi

    def initialize options={}
      @options = Uploadcare::default_settings.merge(options)
      @api_connection = Uploadcare::Connections::ApiConnection.new(@options)
      @upload_connection = Uploadcare::Connections::UploadConnection.new(@options)
    end


    # basic request method
    def request method = :get, path = "/files/", params = {}
      response = @api_connection.send method, path, params
      response.body
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
  end
end
