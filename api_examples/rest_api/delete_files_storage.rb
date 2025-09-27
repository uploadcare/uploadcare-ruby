require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Delete file from storage
uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'

# Method 1: Using File resource
file = Uploadcare::File.new(uuid: uuid)
deleted_file = file.delete
puts "File deleted at: #{deleted_file.datetime_removed}"

# Method 2: Using client interface
client = Uploadcare.client
result = client.delete_file(uuid: uuid)
puts result.inspect
