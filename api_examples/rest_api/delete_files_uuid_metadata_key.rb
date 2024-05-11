require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

puts Uploadcare::FileMetadata.delete('1bac376c-aa7e-4356-861b-dd2657b5bfd2', 'pet')
