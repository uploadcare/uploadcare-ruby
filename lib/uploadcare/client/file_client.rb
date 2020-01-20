module Uploadcare
  class FileClient < ApiStruct::Client
    rest_api 'files'

    def index
      get(path: 'files/')
    end
  end
end
