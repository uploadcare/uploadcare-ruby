require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

document_params = { uuid: ENV.fetch('UPLOADCARE_DOCUMENT_UUID', '1bac376c-aa7e-4356-861b-dd2657b5bfd2'), format: :pdf }
options = { store: '1' }
# for multipage conversion
# options = { store: '1', save_in_group: '1' }
Uploadcare::DocumentConverter.convert_document(params: document_params, options: options)
