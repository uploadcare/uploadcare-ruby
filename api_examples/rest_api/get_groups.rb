require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

groups = Uploadcare::GroupList.list(limit: 10)
groups.each { |group| puts group.inspect }
