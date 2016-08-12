module Uploadcare
  module GroupListApi
    def group_list(params = {})
      data = get '/groups/', params
      list = Uploadcare::Api::GroupList.new self, data
    end
  end
end
