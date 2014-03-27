require 'ostruct'

module Uploadcare
  class Api
    class File < OpenStruct
      def initialize api, uuid_or_cdn_url, data=nil
        result = Uploadcare::Parser.parse_file_string uuid_or_cdn_url
        
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
        load_data! unless is_loaded?
        self
      end
      alias_method :load, :load_data

      def load_data!
        data = @api.get "/files/#{uuid}/"
        set_data(data)

        self
      end
      alias_method :load!, :load_data!

      def is_loaded?
        !send(:datetime_uploaded).nil?
      end
      alias_method :loaded?, :is_loaded?


      def store
        data = @api.put "/files/#{uuid}/storage/"
        set_data data
        self 
      end

      # nil is returning if there is no way to say for sure
      def is_stored?
        return nil unless is_loaded?
        !send(:datetime_stored).nil?
      end
      alias_method :stored?, :is_stored?


      def delete
        data = @api.delete "/files/#{uuid}/storage/"
        set_data data
        self
      end

      # nil is returning if there is no way to say for sure
      def is_deleted?
        return nil unless is_loaded?
        !send(:datetime_removed).nil?
      end
      alias_method :deleted?, :is_deleted?
      alias_method :removed?, :is_deleted?
      alias_method :is_removed?, :is_deleted?


      # Datetime methods
      # practicly try and parse the string to date objects
      ["original", "uploaded", "stored", "removed"].each do |dt|
        define_method "datetime_#{dt}" do
          date = @table["datetime_#{dt}".to_sym]
          if date.is_a?(String)
            begin
              parsed = DateTime.parse(date)
              self.send("datetime_#{dt}=", parsed)
              parsed
            rescue Exception => e
              date
            end
          else
            date
          end
        end
      end
      alias_method :datetime_deleted, :datetime_removed


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