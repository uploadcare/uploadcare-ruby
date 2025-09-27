require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Get project information

# Method 1: Using Project resource
project = Uploadcare::Project.show

puts "Project name: #{project.name}"
puts "Public key: #{project.pub_key}"
puts "Autostore enabled: #{project.autostore_enabled}"
puts "Collaborators: #{project.collaborators.count}"

# Method 2: Using client interface
client = Uploadcare.client
project_info = client.project_info
puts project_info.inspect
