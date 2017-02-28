module Uploadcare
  module GroupListApi
    # Available options:
    #
    #   limit -- a number of objects retrieved per request. Default: 100
    #   ordering -- sorting order of groups in a list. Default: datetime_creataed
    #   from -- a starting point for filtering groups.
    #
    # Documentation: http://uploadcare.com/documentation/rest/#group-groups
    def group_list options={}
      Validators::GroupListOptionsValidator.new(options).validate

      data = get '/groups/', options
      list = Uploadcare::Api::GroupList.new self, data, options
    end
  end
end
