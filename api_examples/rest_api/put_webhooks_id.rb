require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

webhook_id = 1_473_151
options = {
  target_url: 'https://yourwebhook.com',
  event: 'file.uploaded',
  is_active: true,
  signing_secret: 'webhook-secret'
}
Uploadcare::Webhook.update(webhook_id, options)
