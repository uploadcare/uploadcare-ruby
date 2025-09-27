require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Store a single file
uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'

# Method 1: Using File resource
file = Uploadcare::File.new(uuid: uuid)
stored_file = file.store
puts "File stored at: #{stored_file.datetime_stored}"

# Method 2: Using client interface
client = Uploadcare.client
result = client.store_file(uuid: uuid)
puts result.inspect
