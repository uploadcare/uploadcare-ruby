module Uploadcare
  class FileClient < ApiStruct::Client
    rest_api 'files'

    def index
      get(path: 'files/', headers: AuthenticationHeader.call)
    end
  end
end
