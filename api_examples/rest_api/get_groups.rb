require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# List file groups

# Method 1: Using Group.list
groups = Uploadcare::Group.list

groups.each do |group|
  puts "Group ID: #{group.id}"
  puts "Files count: #{group.files_count}"
  puts "Created: #{group.datetime_created}"
  puts "---"
end

# Method 2: Using client interface
client = Uploadcare.client
groups = client.list_groups
groups.each { |group| puts group.inspect }
