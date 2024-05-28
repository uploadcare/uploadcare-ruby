require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

source_object = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
target = 'custom_storage_connected_to_the_project'
copied_file_url = Uploadcare::File.remote_copy(source_object, target, make_public: true)
puts copied_file_url
