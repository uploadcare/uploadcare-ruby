require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

source = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
copied_file = Uploadcare::File.local_copy(source, store: true)
puts copied_file.uuid
