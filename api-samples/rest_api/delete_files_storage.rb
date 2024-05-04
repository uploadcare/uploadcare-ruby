require 'uploadcare'
Uploadcare.config.public_key = "YOUR_PUBLIC_KEY"
Uploadcare.config.secret_key = "YOUR_SECRET_KEY"

uuids = ["21975c81-7f57-4c7a-aef9-acfe28779f78", "cbaf2d73-5169-4b2b-a543-496cf2813dff"]
puts Uploadcare::FileList.batch_delete(uuids)
