require 'ostruct'

module Uploadcare
  class Api
    class File < OpenStruct
      def initialize api, uuid_or_cdn_url, data=nil
        result = Uploadcare::Parser.parse(uuid_or_cdn_url)

        unless result.is_a?(Uploadcare::Parser::File)
          msg = "invalid CDN URL or UUID was given for file: #{uuid_or_cdn_url}."
          if result.is_a?(Uploadcare::Parser::Group)
            msg = msg + "\n Group UUID was given. Try call @api.group if it is what you intended."
          end
          raise msg
        end
        
        file = {uuid: result["uuid"], operations: result["operations"]}

        @api = api

        super file

        set_data(data) if data
      end

      def cdn_url add_operations=false
        if add_operations
          cdn_url_with_operations
        else
          cdn_url_without_operations
        end
      end
      alias_method :public_url, :cdn_url


      def cdn_url_without_operations
        @api.options[:static_url_base] + "/#{@table[:uuid]}/"
      end
      alias_method :public_url_without_operations, :cdn_url_without_operations


      def cdn_url_with_operations
        url = cdn_url_without_operations
        unless operations.empty?
          ops = operations.join("/-/")
          url = url + "-/#{ops}/"
        end
        url
      end
      alias_method :public_url_with_operations, :cdn_url_with_operations


      def load_data
        unless is_loaded?
          load_data!
        end

        self
      end


      def load_data!
        data = @api.get "/files/#{uuid}/"
        set_data data

        self
      end


      def is_loaded?
        !send(:datetime_uploaded).nil?
      end
      alias_method :loaded?, :is_loaded?


      def store
        data = @api.put "/files/#{uuid}/storage/"
        set_data data
        self 
      end

      def is_stored?
      end
      alias_method :stored?, :is_stored?


      def delete
        data = @api.delete "/files/#{uuid}/storage/"
        set_data data
      end

      def is_deleted?
      end
      alias_method :deleted?, :is_stored?


      private
        def set_data data
          if data.respond_to? :each
            data.each do |key, value|
              self.send "#{key}=", value
            end
          else
            self.data = data
          end
        end
    end
  end
end