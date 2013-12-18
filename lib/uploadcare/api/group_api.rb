module Uploadcare
  module GroupApi

    def group uuid_or_cdn_url
      group = Uploadcare::Api::Group.new self, uuid_or_cdn_url
    end


    def create_group ary
      unless ary.kind_of?(Array)
        raise ArgumentError.new "You should send and array of files or valid UUIDs"
      else
        if ary.select {|f| !!f.kind_of?(Uploadcare::Api::File) }.any?
          files = Hash.new
          ary.each_with_index do |file, i|
            files["files[#{i}]"] = file.uuid
          end
        elsif ary.select {|f| !!f.kind_of?(String) }.any?
          files = Hash.new
          ary.each_with_index do |uuid, i|
            files["files[#{i}]"] = uuid
          end
        else
          raise ArgumentError.new "You should send and array of files or valid UUIDs"
        end
      end


      data = {
        pub_key: @options[:public_key],
      }

      data.merge! files
      post = parse(upload_request :post, "/group/", data)
      group = Uploadcare::Api::Group.new self, post["id"], post
    end
  end
end