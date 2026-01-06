#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', nil)
  config.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', nil)
end

puts 'Creating a file group...'
puts

# First, upload some files to get UUIDs
upload_client = Uploadcare::UploadClient.new

file1 = File.open('spec/fixtures/kitten.jpeg', 'rb')
file2 = File.open('spec/fixtures/another_kitten.jpeg', 'rb')

response1 = upload_client.upload_file(file1, store: true)
response2 = upload_client.upload_file(file2, store: true)

file1.close
file2.close

# Extract UUIDs from responses
uuid1 = response1.values.first
uuid2 = response2.values.first

puts 'Uploaded files:'
puts "  File 1: #{uuid1}"
puts "  File 2: #{uuid2}"
puts

# Create a group from the uploaded files
files = [uuid1, uuid2]
group_response = upload_client.create_group(files)

puts 'Group created successfully!'
puts "  Group ID: #{group_response['id']}"
puts "  Files count: #{group_response['files_count']}"
puts "  CDN URL: #{group_response['cdn_url']}"
puts "  Created at: #{group_response['datetime_created']}"
puts

# You can also use the Group resource
group = Uploadcare::Group.create(files)
puts 'Using Group.create:'
puts "  Group ID: #{group.id}"
puts "  Files count: #{group.files_count}"
