require 'uploadcare'
Uploadcare.config.public_key = "YOUR_PUBLIC_KEY"
Uploadcare.config.secret_key = "YOUR_SECRET_KEY"

uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
key = 'pet'
value = 'dog'
Uploadcare::FileMetadata.update(uuid, key, value)
