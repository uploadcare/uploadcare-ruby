require 'ostruct'

module Uploadcare
  class Api
    class Group < OpenStruct
      def initialize api, uuid_or_cdn_url, data=nil
        result = Uploadcare::Parser.parse_group_string(uuid_or_cdn_url) 

        @api = api
        group = {uuid: result.uuid, files_count: result.count}
        super group

        # if data is suplide - just pass it to builder.
        set_data(data) if data
      end

      def cdn_url
        @api.options[:static_url_base] + "/#{uuid}/"
      end

      def file_cdn_url index=0
        raise ArgumentError.new "The index was given is greater than files count in group." if index + 1 > files_count
        cdn_url + "nth/#{index}/"
      end

      # Loading logic
      def is_loaded?
        !send(:files).nil?
      end
      alias_method :loaded?, :is_loaded? 

      def load_data
        unless is_loaded?
          load_data!
        end
        self
      end
      alias_method :load, :load_data

      def load_data!
        data = @api.get "/groups/#{uuid}/"
        set_data data

        self
      end
      alias_method :load!, :load_data!

      # Store group (and all files in group)
      def store
        unless is_stored?
          store!
        end
        self
      end

      def store!
        data = @api.put "/groups/#{uuid}/storage/"
        set_data(data)
        self
      end

      def is_stored?
        return nil unless is_loaded?
        !send(:datetime_stored).nil?
      end
      alias_method :stored?, :is_stored?


      ["created", "stored"].each do |dt|
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


      private
        def set_data data
          data = map_files(data) unless data["files"].nil?

          if data.respond_to? (:each)
            data.each do |k, v|
              self.send "#{k}=", v
            end
          end

          @is_loaded = true
        end

        # map files (hashes basicly) to
        # actual File objects
        def map_files data
          data["files"].map! do |file|
            unless file.nil?
              Uploadcare::Api::File.new(@api, file["uuid"], file)
            else
              file
            end
          end

          data
        end
    end
  end
end
