require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Batch store multiple files
uuids = [
  '1bac376c-aa7e-4356-861b-dd2657b5bfd2',
  'a4b9db2f-1591-4f4c-8f68-94018924525d'
]

# Batch store
result = Uploadcare::File.batch_store(uuids)

if result.status == 'success'
  puts "Successfully stored #{result.result.count} files:"
  result.result.each do |file|
    puts "  - #{file.uuid}: stored at #{file.datetime_stored}"
  end
end

# Handle any problems
if result.problems.any?
  puts "Problems encountered:"
  result.problems.each do |uuid, error|
    puts "  - #{uuid}: #{error}"
  end
end
