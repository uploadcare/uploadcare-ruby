require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

uuid = '0d712319-b970-4602-850c-bae1ced521a6~1'
info = Uploadcare::Group.info(uuid)
puts info.inspect
