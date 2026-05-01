require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

File.open('image.png') do |source_file|
  Uploadcare::Uploader.upload(source_file, store: 'auto')
end
