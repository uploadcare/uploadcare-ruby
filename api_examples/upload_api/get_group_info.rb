require 'uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

uuid = ENV.fetch('UPLOADCARE_GROUP_UUID', '0d712319-b970-4602-850c-bae1ced521a6~1')
info = Uploadcare::Group.info(group_id: uuid)
puts info.inspect
