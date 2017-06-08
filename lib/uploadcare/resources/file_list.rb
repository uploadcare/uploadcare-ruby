require 'ostruct'
require_relative 'resource_list'

module Uploadcare
  class Api
    class FileList < ResourceList
      private

      def to_resource(api, file_data)
        Uploadcare::Api::File.new(api, file_data['uuid'], file_data)
      end
    end
  end
end
