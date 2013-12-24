require 'ostruct'

module Uploadcare
  class Api
    class FileList < OpenStruct
      def initialize api, data
        @api = api

        unless data["results"].nil?
          data["results"].map! do |file| 
            Uploadcare::Api::File.new @api, file["uuid"], file
          end
        end

        super data
      end

      # Array-like behavior
      def [] index
        results[index] if defined?(:results)
      end

      def to_a
        results if defined?(:results)
      end

      # List navigation
      def next_page
        @api.file_list(page+1) unless send(:next).nil?
      end

      def go_to index
        @api.file_list(index) unless index > pages
      end

      def previous_page
        @api.file_list(page-1) unless previous.nil?
      end
    end
  end
end