require 'uploadcare'
Uploadcare.config.public_key = "YOUR_PUBLIC_KEY"
Uploadcare.config.secret_key = "YOUR_SECRET_KEY"

options = {
  target_url: "https://yourwebhook.com",
  event: "file.uploaded",
  is_active: true
}
Uploadcare::Webhook.create(**options)
