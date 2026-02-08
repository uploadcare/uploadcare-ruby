require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

uuids = ENV.fetch('UPLOADCARE_FILE_UUIDS',
                  '21975c81-7f57-4c7a-aef9-acfe28779f78,cbaf2d73-5169-4b2b-a543-496cf2813dff').split(',')
puts Uploadcare::File.batch_delete(uuids: uuids)
