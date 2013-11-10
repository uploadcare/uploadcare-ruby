require 'ostruct'

module Uploadcare
  class Api
    class Project < OpenStruct
      def initialize api
        @api = api
        data = @api.get "/project/"
        super data
      end

      # def load data
      #   if data.respond_to? :each
      #     data.each do |key, value|
      #       self.send "#{key}=", value
      #     end
      #   end
      # end
    end
  end
end