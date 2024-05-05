# Uploadcare lib provides high level API for multipart uploads that does everything for you

require 'uploadcare'
Uploadcare.config.public_key = "YOUR_PUBLIC_KEY"
Uploadcare.config.secret_key = "YOUR_SECRET_KEY"

source_file = File.open('image.png')
uploaded_file = Uploadcare::Uploader.upload(source_file, store: "auto")
