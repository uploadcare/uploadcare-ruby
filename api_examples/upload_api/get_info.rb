require 'uploadcare'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

uuid = ENV.fetch('UPLOADCARE_FILE_UUID', '740e1b8c-1ad8-4324-b7ec-112c79d8eac2')
info = Uploadcare::File.info(uuid: uuid)
puts info.inspect
