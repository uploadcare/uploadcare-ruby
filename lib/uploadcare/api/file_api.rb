require "uri"

module Uploadcare
  module FileApi
    # create file from uuid or cdn url
    def file uuid_or_cdn_url
      if uuid_or_cdn_url =~ Uploadcare::UUID_REGEX
        file = file_from_uuid(uuid_or_cdn_url)
      elsif uuid_or_cdn_url =~ Uploadcare::CDN_URL_REGEX
        file = file_from_cdn_url(uuid_or_cdn_url)
      else
        raise ArgumentError.new "Expecting file UUID or CDN url for file."
      end
    end


    def file_from_uuid uuid
      file = Uploadcare::Api::File.new self, uuid
    end


    def file_from_cdn_url url
      matched = Uploadcare::CDN_URL_REGEX.match(url)
      
      uuid = matched[:uuid]
      unless matched[:operations].nil?
        operations = matched[:operations].split("/-/")
      else
        operations = []
      end

      file = Uploadcare::Api::File.new self, uuid, {operations: operations}
    end
  end
end