# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    Uploadcare.config.public_key = 'demopublickey'
    Uploadcare.config.secret_key = 'demoprivatekey'
    Uploadcare.config.auth_type = 'Uploadcare'
    Uploadcare.config.multipart_size_threshold = 100 * 1024 * 1024
  end
end
