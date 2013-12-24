require 'ostruct'

module Uploadcare
  class Api
    class Group < OpenStruct
      def initialize api, uuid_or_cdn_url, data=nil
        result = Uploadcare::Parser.parse(uuid_or_cdn_url)

        unless result.is_a?(Uploadcare::Parser::Group)
          msg = "invalid CDN URL or UUID was given for group: #{uuid_or_cdn_url}."
          if result.is_a?(Uploadcare::Parser::File)
            msg = msg + "\n File UUID was given. Try call @api.file if it is what you intended."
          end
          raise msg
        end

        @api = api
        # self.files_count = result["count"]
        group = {uuid: result["uuid"], files_count: result["count"]}
        super group

        # if data is suplide - just pass it to builder.
        set_data(data) if data
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
        data = @api.put "/groups/#{uuid}/storage"
        set_data(data)
        self
      end

      def is_stored?
        return nil unless is_loaded?
        !send(:datetime_stored).nil?
      end
      alias_method :stored?, :is_stored?


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