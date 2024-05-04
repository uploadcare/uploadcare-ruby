require 'uploadcare'
Uploadcare.config.public_key = "YOUR_PUBLIC_KEY"
Uploadcare.config.secret_key = "YOUR_SECRET_KEY"

request_id = "d1fb31c6-ed34-4e21-bdc3-4f1485f58e21"
result = Uploadcare::Addons.ws_rekognition_detect_labels_status(request_id)
puts result.status
