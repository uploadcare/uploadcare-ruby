require 'uploadcare'
Uploadcare.config.public_key = "YOUR_PUBLIC_KEY"
Uploadcare.config.secret_key = "YOUR_SECRET_KEY"

puts Uploadcare::Group.delete("c5bec8c7-d4b6-4921-9e55-6edb027546bc~1")
