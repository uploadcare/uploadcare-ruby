require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Update an existing webhook
webhook_id = 123  # Webhook ID from creation or list

# Method 1: Using Webhook.update class method
updated_webhook = Uploadcare::Webhook.update(
  webhook_id,
  target_url: 'https://example.com/webhook/new',
  event: 'file.stored',
  is_active: true,
  signing_secret: 'new_secret'
)

puts "Webhook updated"
puts "New target: #{updated_webhook.target_url}"
puts "New event: #{updated_webhook.event}"

# Method 2: Using instance method
webhook = Uploadcare::Webhook.list.find { |w| w.id == webhook_id }
webhook.update(
  target_url: 'https://example.com/webhook/updated',
  is_active: false
)
puts "Webhook deactivated"
