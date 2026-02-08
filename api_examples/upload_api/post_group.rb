require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

uuids = ENV.fetch('UPLOADCARE_GROUP_FILE_UUIDS',
                  'd6d34fa9-addd-472c-868d-2e5c105f9fcd,b1026315-8116-4632-8364-607e64fca723').split(',')
Uploadcare::Group.create(uuids: uuids)
