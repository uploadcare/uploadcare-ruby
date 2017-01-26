module Uploadcare
  module GroupListApi
    def group_list from=nil, limit=nil
      data = get '/groups/', {from: from, limit: limit}.reject{|_,v| v.nil?}
      list = Uploadcare::Api::GroupList.new self, data
    end
  end
end