require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# List all webhooks

# Method 1: Using Webhook.list
webhooks = Uploadcare::Webhook.list

webhooks.each do |webhook|
  puts "ID: #{webhook.id}"
  puts "Target URL: #{webhook.target_url}"
  puts "Event: #{webhook.event}"
  puts "Active: #{webhook.is_active}"
  puts "---"
end

# Method 2: Using client interface
client = Uploadcare.client
webhooks = client.list_webhooks
webhooks.each { |webhook| puts webhook.inspect }
