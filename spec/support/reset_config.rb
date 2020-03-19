# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    Uploadcare.config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
    Uploadcare.config.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY')
    Uploadcare.config.auth_type = 'Uploadcare'
    Uploadcare.config.multipart_size_threshold = 100 * 1024 * 1024
  end
end
