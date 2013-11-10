require "uri"

module Uploadcare
  module ProjectApi
    def project
      @project ||= Uploadcare::Api::Project.new self 
    end
  end
end