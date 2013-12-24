require "uri"

module Uploadcare
  module FileApi
    def file uuid_or_cdn_url
      file = Uploadcare::Api::File.new self, uuid_or_cdn_url
    end
  end
end