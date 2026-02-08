require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

uuid = ENV.fetch('UPLOADCARE_DOCUMENT_UUID', '740e1b8c-1ad8-4324-b7ec-112c79d8eac2')
converter = Uploadcare::DocumentConverter.new
puts converter.info(uuid: uuid).inspect
