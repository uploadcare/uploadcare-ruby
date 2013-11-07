require 'ostruct'

module Uploadcare
  class Api
    class File < OpenStruct
      def initialize api, uuid, info={}
        @api = api
        super(uuid: uuid, info: info)
      end

      def cdn_url
        @api.options[:static_url_base] + "/#{@table[:uuid]}/"
      end
      alias_method :public_url, :cdn_url
      
    end
  end
end