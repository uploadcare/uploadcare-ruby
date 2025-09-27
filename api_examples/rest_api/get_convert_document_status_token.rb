require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Check document conversion status
token = 123456  # Token from conversion request

# Check status
status = Uploadcare::DocumentConverter.status(token)

case status[:status]
when 'finished'
  puts "Conversion completed"
  puts "Result UUID: #{status[:result][:uuid]}"
when 'processing'
  puts "Conversion in progress..."
when 'failed'
  puts "Conversion failed: #{status[:error]}"
end
