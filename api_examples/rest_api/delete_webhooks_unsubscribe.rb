require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Delete/unsubscribe from a webhook
target_url = 'https://example.com/webhook/uploadcare'

# Delete webhook by target URL
Uploadcare::Webhook.delete(target_url)
puts "Webhook unsubscribed: #{target_url}"
