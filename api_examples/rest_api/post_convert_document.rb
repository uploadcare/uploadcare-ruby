require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

document_params = { uuid: '1bac376c-aa7e-4356-861b-dd2657b5bfd2', format: :pdf }
options = { store: '1' }
# for multipage conversion
# options = { store: '1', save_in_group: '1' }
Uploadcare::DocumentConverter.convert(document_params, options)
