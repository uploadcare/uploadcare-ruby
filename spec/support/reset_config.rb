# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
    Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY')
    Uploadcare.configuration.auth_type = 'Uploadcare.Simple'
    Uploadcare.configuration.multipart_size_threshold = 100 * 1024 * 1024
  end
end
