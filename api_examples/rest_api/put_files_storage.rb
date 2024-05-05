require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

uuids = %w[
  b7a301d1-1bd0-473d-8d32-708dd55addc0
  1bac376c-aa7e-4356-861b-dd2657b5bfd2
]
Uploadcare::FileList.batch_store(uuids)
