require 'ostruct'

module Uploadcare
  class Api
    class Project < OpenStruct
      def initialize api
        @api = api
        data = @api.get "/project/"
        super data
      end
    end
  end
end