#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/uploadcare'
require 'dotenv/load'

file_paths = ARGV

if file_paths.empty?
  puts 'Usage: ruby batch_upload.rb <file1> <file2> <file3> ...'
  puts 'Example: ruby batch_upload.rb photo1.jpg photo2.jpg photo3.jpg'
  exit 1
end

file_paths.each do |path|
  unless File.exist?(path)
    puts "Error: File not found: #{path}"
    exit 1
  end
end

puts "Batch Upload - #{file_paths.length} files"
puts '=' * 50
puts

files = file_paths.map { |path| File.open(path, 'rb') }

begin
  client = Uploadcare::Client.new(
    public_key: ENV.fetch('UPLOADCARE_PUBLIC_KEY'),
    secret_key: ENV.fetch('UPLOADCARE_SECRET_KEY')
  )

  results = client.uploads.upload(files, store: true)

  puts '✓ Batch upload complete!'
  puts
  puts 'Results:'
  puts '-' * 50

  results.each_with_index do |file, index|
    puts "#{index + 1}. #{file.original_filename}"
    puts "   UUID: #{file.uuid}"
    puts "   CDN URL: #{file.cdn_url}"
    puts
  end

  puts "Successfully uploaded #{results.length} files"
rescue StandardError => e
  puts "✗ Batch upload failed: #{e.message}"
  exit 1
ensure
  files.each(&:close)
end
