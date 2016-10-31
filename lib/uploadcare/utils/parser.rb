require 'ostruct'

module Uploadcare
  module Parser

    META_URL = /
        (?<uuid>[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12} # base uuid
        ~?(?<count>\d+)?) # optional count
        (?:\/-\/(?<operations>.*?))?\/?$ # optional operations
      /ix

    def self.parse_file_string string
      result = Uploadcare::Parser.parse(string)

      unless result.is_a?(Uploadcare::Parser::File)
        msg = "invalid CDN URL or UUID was given for file: #{uuid_or_cdn_url}."
        if result.is_a?(Uploadcare::Parser::Group)
          msg = msg + "\n Group UUID was given. Try call @api.group if it is what you intended."
        end
        raise msg
      end

      result
    end


    def self.parse_group_string string
      result = Uploadcare::Parser.parse(string)

      unless result.is_a?(Uploadcare::Parser::Group)
        msg = "invalid CDN URL or UUID was given for group: #{uuid_or_cdn_url}."
        if result.is_a?(Uploadcare::Parser::File)
          msg = msg + "\n File UUID was given. Try call @api.file if it is what you intended."
        end
        raise msg
      end

      result
    end

    def self.parse string
      matched = META_URL.match(string)

      raise ArgumentError.new("Invalid UUID or url was given") if matched.nil?

      # just a simple hash - easy to pass next
      captured = Hash[ matched.names.zip( matched.captures ) ]

      # raise an error if no uuid was given in the sting
      raise ArgumentError.new("Invalid UUID or url was given") if captured["uuid"].nil?

      # operations sring to array of operations
      if captured["operations"]
        captured["operations"] = captured["operations"].split("/-/")
      else
        captured["operations"] = []
      end

      # if count was given - it is a group
      if captured["count"]
        obj = Group.new captured
      else
        obj = File.new captured
      end
    end

    class File < OpenStruct
    end

    class Group < OpenStruct
    end
  end
end
