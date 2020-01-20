<<<<<<< 492757944f839e4ad48d57d1fecd75f39acfb644
# frozen_string_literal: true

=======
>>>>>>> feat: basic requests
ApiStruct::Settings.configure do |config|
  config.endpoints = {
    rest_api: {
      root: 'https://api.uploadcare.com',
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/vnd.uploadcare-v0.5+json'
      }
    }
  }
end
