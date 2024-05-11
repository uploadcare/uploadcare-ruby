require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

source_url = 'https://source.unsplash.com/featured'
Uploadcare::Uploader.upload(source_url, store: 'auto')
