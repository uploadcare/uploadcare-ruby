require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Execute AWS Rekognition label detection
uuid = 'FILE_UUID'

# Execute detection
result = Uploadcare::AddOns.aws_rekognition_detect_labels(uuid)
request_id = result[:request_id]

puts "Detection started with request ID: #{request_id}"
puts "Check status with: Uploadcare::AddOns.aws_rekognition_detect_labels_status('#{request_id}')"

# Results will be available in file's appdata when complete
