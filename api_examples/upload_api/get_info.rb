require 'uploadcare'
Uploadcare.config.public_key = "YOUR_PUBLIC_KEY"
Uploadcare.config.secret_key = "YOUR_SECRET_KEY"

uuid = '740e1b8c-1ad8-4324-b7ec-112c79d8eac2'
info = Uploadcare::File.info(uuid)
puts info.inspect
