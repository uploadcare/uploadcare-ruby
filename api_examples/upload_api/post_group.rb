require 'uploadcare'
Uploadcare.config.public_key = "YOUR_PUBLIC_KEY"
Uploadcare.config.secret_key = "YOUR_SECRET_KEY"

uuids = [
  'd6d34fa9-addd-472c-868d-2e5c105f9fcd',
  'b1026315-8116-4632-8364-607e64fca723/-/resize/x800/'
]
group = Uploadcare::Group.create(uuids)
