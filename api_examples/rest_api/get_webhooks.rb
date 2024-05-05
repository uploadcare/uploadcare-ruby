require 'uploadcare'
Uploadcare.config.public_key = "YOUR_PUBLIC_KEY"
Uploadcare.config.secret_key = "YOUR_SECRET_KEY"

webhooks = Uploadcare::Webhook.list
webhooks.each { |webhook| puts webhook.inspect }
