require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

uuids = ENV.fetch('UPLOADCARE_FILE_UUIDS',
                  'b7a301d1-1bd0-473d-8d32-708dd55addc0,1bac376c-aa7e-4356-861b-dd2657b5bfd2').split(',')
puts Uploadcare::File.batch_store(uuids: uuids)
