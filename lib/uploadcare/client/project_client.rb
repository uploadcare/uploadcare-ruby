# https://uploadcare.com/docs/api_reference/rest/handling_projects/

module Uploadcare
  class ProjectClient < ApiStruct::Client
    rest_api 'projects'

    def show
      get(path: "project/", headers: SimpleAuthenticationHeader.call)
    end
  end
end
