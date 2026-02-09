require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

webhook_id = 1_473_151
options = {
  target_url: 'https://yourwebhook.com',
  event: 'file.uploaded',
  is_active: true,
  signing_secret: 'webhook-secret'
}
updated_webhook = Uploadcare::Webhook.update(id: webhook_id, **options)
puts updated_webhook.inspect
