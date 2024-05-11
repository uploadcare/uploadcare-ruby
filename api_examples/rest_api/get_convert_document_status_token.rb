require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

token = 32_921_143
puts Uploadcare::DocumentConverter.status(token)
