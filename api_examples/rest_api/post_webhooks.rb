require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Create a new webhook
webhook = Uploadcare::Webhook.create(
  target_url: 'https://example.com/webhook/uploadcare',
  event: 'file.uploaded',  # Events: file.uploaded, file.stored, file.deleted, etc.
  is_active: true,
  signing_secret: 'your_webhook_secret',  # For signature verification
  version: '0.7'
)

puts "Webhook created"
puts "ID: #{webhook.id}"
puts "Target: #{webhook.target_url}"
puts "Event: #{webhook.event}"
puts "Active: #{webhook.is_active}"
