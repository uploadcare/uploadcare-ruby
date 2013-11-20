require 'ostruct'

module Uploadcare
  module Parser

    META_URL = /
        (?<uuid>[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12} # base uuid
        ~?(?<count>\d+)?) # optional count
        (?:\/-\/(?<operations>.*?))?\/?$ # optional operations
      /ix

    def self.parse string
      matched = META_URL.match(string)

      # just a simple hash - easy to pass next
      captured = Hash[ matched.names.zip( matched.captures ) ]

      # raise an error if no uuid was given in the sting
      raise "Invalid UUID or url was given" if captured["uuid"].nil?

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