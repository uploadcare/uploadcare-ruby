require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

token = '945ebb27-1fd6-46c6-a859-b9893712d650'
puts Uploadcare::Uploader.get_upload_from_url_status(token)
