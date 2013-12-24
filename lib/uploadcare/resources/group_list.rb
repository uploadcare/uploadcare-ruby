require 'ostruct'

module Uploadcare
  class Api
    class GroupList < OpenStruct
      def initialize api, data
        @api = api

        unless data["results"].nil?
          data["results"].map! do |group|
            Uploadcare::Api::Group.new @api, group["id"], group
          end
        end

        super data
      end

      def [] index
        results[index] if defined?(:results)
      end

      def to_a
        results if defined?(:results)
      end

      def groups
        results if defined?(:results)
      end
    end
  end
end