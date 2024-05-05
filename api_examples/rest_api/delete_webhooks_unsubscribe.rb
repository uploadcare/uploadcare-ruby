require 'uploadcare'
Uploadcare.config.public_key = "YOUR_PUBLIC_KEY"
Uploadcare.config.secret_key = "YOUR_SECRET_KEY"

puts Uploadcare::Webhook.delete('https://yourwebhook.com')
