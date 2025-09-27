require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Check AWS Rekognition label detection status
request_id = 'REQUEST_ID_FROM_EXECUTE'

# Check status
status = Uploadcare::AddOns.aws_rekognition_detect_labels_status(request_id)

if status[:status] == 'done'
  puts "Labels detected successfully"
  # Labels are now available in file's appdata
elsif status[:status] == 'error'
  puts "Detection failed: #{status[:error]}"
else
  puts "Detection in progress..."
end
