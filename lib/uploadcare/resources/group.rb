require 'ostruct'

module Uploadcare
  class Api
    class Group < OpenStruct
      def initialize api, uuid, data=nil
        @api = api
        @is_loaded = false
        super uuid: uuid

        # if data is suplide - just pass it to builder.
        if data
          set_data(data)
        # if no data is suplide - build files_count from uuid string
        else
          matched = Uploadcare::GROUP_UUID_REGEX.match(uuid)
          self.files_count = matched[:count]
        end

        self
      end

      def is_loaded?
        @is_loaded
      end
      alias_method :loaded?, :is_loaded? 

      def load_data
        unless is_loaded?
          data = @api.get "/groups/#{uuid}/"
          set_data data
        end

        self
      end


      def load_data!
        data = @api.get "/groups/#{uuid}/"
        set_data data

        self
      end

      private
        def set_data data
          unless data["files"].nil?
            data["files"].map! do |file|
              unless file.nil?
                Uploadcare::Api::File.new(@api, file["uuid"], file)
              else
                file
              end
            end
          end

          if data.respond_to? (:each)
            data.each do |k, v|
              self.send "#{k}=", v
            end
          end

          @is_loaded = true
        end
    end
  end
end