require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Check video conversion status
token = 123456  # Token from conversion request

# Check status
status = Uploadcare::VideoConverter.status(token)

case status[:status]
when 'finished'
  puts "Video conversion completed"
  puts "Result UUID: #{status[:result][:uuid]}"
  puts "Thumbnails: #{status[:result][:thumbnails_group_uuid]}"
when 'processing'
  puts "Conversion in progress..."
when 'failed'
  puts "Conversion failed: #{status[:error]}"
end
