require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

options = {
  target_url: ENV.fetch('UPLOADCARE_WEBHOOK_TARGET_URL', 'https://yourwebhook.com'),
  event: 'file.uploaded',
  is_active: true
}
Uploadcare::Webhook.create(**options)
