require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

request_id = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
result = Uploadcare::Addons.remove_bg_status(request_id)
puts result.status
