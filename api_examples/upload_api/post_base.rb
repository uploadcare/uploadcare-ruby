require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

source_file = File.open('image.png')
Uploadcare::Uploader.upload(source_file, store: 'auto')
