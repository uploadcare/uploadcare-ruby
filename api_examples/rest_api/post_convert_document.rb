require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Convert document to different format
uuid = 'DOCUMENT_UUID'

# Check supported formats first
info = Uploadcare::DocumentConverter.info(uuid)
puts "Current format: #{info[:format][:name]}"
puts "Can convert to: #{info[:format][:conversion_formats].map { |f| f[:name] }.join(', ')}"

# Convert document
result = Uploadcare::DocumentConverter.convert(
  [
    {
      uuid: uuid,
      format: 'pdf',    # Target format
      page: 1           # For image outputs, specific page number
    }
  ],
  store: true  # Store the result
)

token = result[:result].first[:token]
puts "Conversion started with token: #{token}"

# Check status
status = Uploadcare::DocumentConverter.status(token)
if status[:status] == 'finished'
  puts "Converted file UUID: #{status[:result][:uuid]}"
end
