require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Scan file for viruses
uuid = 'FILE_UUID'

# Execute virus scan with auto-purge if infected
result = Uploadcare::AddOns.uc_clamav_virus_scan(
  uuid,
  purge_infected: true  # Automatically delete if infected
)

request_id = result[:request_id]
puts "Virus scan started with request ID: #{request_id}"

# Check status
status = Uploadcare::AddOns.uc_clamav_virus_scan_status(request_id)
if status[:status] == 'done'
  # Check file's appdata for scan results
  file = Uploadcare::File.new(uuid: uuid)
  info = file.info(include: 'appdata')
  scan_data = info[:appdata][:uc_clamav_virus_scan][:data]
  
  if scan_data[:infected]
    puts "File infected with: #{scan_data[:infected_with]}"
  else
    puts "File is clean"
  end
end
