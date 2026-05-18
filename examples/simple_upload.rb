#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/uploadcare'
require 'dotenv/load'

file_path = ARGV[0]

unless file_path && File.exist?(file_path)
  puts 'Usage: ruby simple_upload.rb <file_path>'
  puts 'Example: ruby simple_upload.rb photo.jpg'
  exit 1
end

puts "Uploading: #{file_path}"
puts "Size: #{(File.size(file_path) / 1024.0).round(2)} KB"
puts

begin
  client = Uploadcare::Client.new(
    public_key: ENV.fetch('UPLOADCARE_PUBLIC_KEY'),
    secret_key: ENV.fetch('UPLOADCARE_SECRET_KEY')
  )

  uploaded_file = File.open(file_path, 'rb') do |file|
    client.files.upload(file, store: true)
  end

  puts '✓ Upload successful!'
  puts
  puts "UUID: #{uploaded_file.uuid}"
  puts "Filename: #{uploaded_file.original_filename}"
  puts "CDN URL: #{uploaded_file.cdn_url}"
  puts
  puts 'The file has been stored and is ready to use.'
rescue StandardError => e
  puts "✗ Upload failed: #{e.message}"
  exit 1
end
