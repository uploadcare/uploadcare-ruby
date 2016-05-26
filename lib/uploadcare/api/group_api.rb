module Uploadcare
  module GroupApi

    def group uuid_or_cdn_url
      group = Uploadcare::Api::Group.new(self, uuid_or_cdn_url)
    end


    def create_group(ary)
      unless ary.kind_of?(Array)
        raise ArgumentError, 'You should send and array of files or valid UUIDs'
      else
        files = {}.tap do |hash|
          if ary.all? { |f| !!f.kind_of?(Uploadcare::Api::File) }
            ary.each_with_index do |file, i|
              hash["files[#{i}]"] = file.uuid
            end
          elsif ary.all? { |f| !!f.kind_of?(String) }
            ary.each_with_index do |uuid, i|
              hash["files[#{i}]"] = uuid
            end
          else
            raise ArgumentError.new "You should send and array of files or valid UUIDs"
          end
        end
      end

      files.merge!(pub_key: @options[:public_key])
      post = @upload_connection.send(:post, "/group/", files)
      group = Uploadcare::Api::Group.new(self, post.body["id"], post.body)
    end
  end
end
