require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Remove file from storage (but keep metadata)
uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'

# Using File resource
file = Uploadcare::File.new(uuid: uuid)
result = file.delete
puts "File removed from storage: #{result.uuid}"
puts "Removal time: #{result.datetime_removed}"
