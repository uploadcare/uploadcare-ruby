require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

request_id = ENV.fetch('UPLOADCARE_ADDON_REQUEST_ID', 'd1fb31c6-ed34-4e21-bdc3-4f1485f58e21')
result = Uploadcare::Addons.aws_rekognition_detect_labels_status(request_id: request_id)
puts result.status
