require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Remove background from image
uuid = 'FILE_UUID'

# Execute background removal with options
result = Uploadcare::AddOns.remove_bg(
  uuid,
  crop: true,           # Crop to object
  type_level: '2',      # Accuracy level (1 or 2)
  type: 'person',       # Object type: person, product, car
  scale: '100%',        # Output scale
  position: 'center'    # Crop position if cropping
)

request_id = result[:request_id]
puts "Background removal started with request ID: #{request_id}"

# Check status
status = Uploadcare::AddOns.remove_bg_status(request_id)
if status[:status] == 'done'
  puts "Result file UUID: #{status[:result][:file_id]}"
end
