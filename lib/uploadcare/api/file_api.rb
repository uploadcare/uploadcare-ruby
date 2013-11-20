require "uri"

module Uploadcare
  module FileApi
    # create file from uuid or cdn url

    def file uuid_or_cdn_url
      result = Uploadcare::Parser.parse(uuid_or_cdn_url)

      unless result.is_a?(Uploadcare::Parser::File)
        msg = "invalid CDN URL or UUID was given for file: #{uuid_or_cdn_url}."
        if result.is_a?(Uploadcare::Parser::Group)
          msg = msg + "\n Group UUID was given. Try call @api.group if it is what you intended."
        end
        raise msg
      end

      file = Uploadcare::Api::File.new self, result["uuid"], {operations: result["operations"]}
    end
  end
end