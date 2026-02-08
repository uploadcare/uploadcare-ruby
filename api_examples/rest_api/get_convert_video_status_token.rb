require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

token = ENV.fetch('UPLOADCARE_VIDEO_TOKEN', '1201016744').to_i
converter = Uploadcare::VideoConverter.new
puts converter.fetch_status(token: token).inspect
