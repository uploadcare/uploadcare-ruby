require 'ostruct'

module Uploadcare
  class Api
    class File < OpenStruct
      def initialize api, uuid
        @api = api

        unless uuid =~ Uploadcare::UUID_REGEX
          raise ArgumentError.new "ivalid UUID was given"
        end

        super(uuid: uuid)
      end

      def cdn_url
        @api.options[:static_url_base] + "/#{@table[:uuid]}/"
      end
      alias_method :public_url, :cdn_url


      def load_data
        unless is_loaded?
          data = @api.get "/files/#{uuid}/"
          set_data data
        end

        self
      end


      def load_data!
        data = @api.get "/files/#{uuid}/"
        set_data data

        self
      end


      def is_loaded?
        @is_loaded
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
            @is_loaded = true
          end
        end
    end
  end
end