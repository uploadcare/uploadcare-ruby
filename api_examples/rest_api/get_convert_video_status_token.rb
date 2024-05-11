require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

token = 1_201_016_744
puts Uploadcare::VideoConverter.status(token)
