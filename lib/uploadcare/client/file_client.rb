module Uploadcare
  class FileClient < ApiStruct::Client
    rest_api 'files'

    def index
      # Gets list of files without pagination fields
      response = get(path: 'files/', headers: SimpleAuthenticationHeader.call)
      response.fmap { |i| i[:results] }
    end

    def info(uuid)
      response = get(path: "files/#{uuid}/", headers: SimpleAuthenticationHeader.call)
    end
  end
end
