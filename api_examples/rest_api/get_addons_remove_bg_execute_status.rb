require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

request_id = ENV.fetch('UPLOADCARE_ADDON_REQUEST_ID', '1bac376c-aa7e-4356-861b-dd2657b5bfd2')
result = Uploadcare::Addons.remove_bg_status(request_id: request_id)
puts result.status
