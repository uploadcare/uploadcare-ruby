require 'ostruct'
require_relative 'resource_list'

module Uploadcare
  class Api
    class GroupList < ResourceList
      private

      def to_resource(api, group_data)
        Uploadcare::Api::Group.new api, group_data["id"], group_data
      end
    end
  end
end
