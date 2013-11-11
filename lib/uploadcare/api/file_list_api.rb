module Uploadcare
  module FileListApi
    def file_list page=1
      data = get '/files/', {page: page}
      list = Uploadcare::Api::FileList.new self, data
    end
  end
end