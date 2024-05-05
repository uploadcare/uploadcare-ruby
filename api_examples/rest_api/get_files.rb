require 'uploadcare'
Uploadcare.config.public_key = "YOUR_PUBLIC_KEY"
Uploadcare.config.secret_key = "YOUR_SECRET_KEY"

list = Uploadcare::FileList.file_list(stored: true, removed: false, limit: 100)
list.each { |file| puts file.inspect }
