#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/uploadcare'
require 'dotenv/load'

file_paths = ARGV

if file_paths.empty?
  script_name = File.basename($PROGRAM_NAME)
  puts "Usage: ruby examples/#{script_name} <file1> <file2> <file3> ..."
  puts "Example: ruby examples/#{script_name} photo1.jpg photo2.jpg photo3.jpg"
  exit 1
end

file_paths.each do |path|
  unless File.exist?(path)
    puts "Error: File not found: #{path}"
    exit 1
  end
end

puts "Group Creation - #{file_paths.length} files"
puts '=' * 50
puts

begin
  client = Uploadcare::Client.new(
    public_key: ENV.fetch('UPLOADCARE_PUBLIC_KEY'),
    secret_key: ENV.fetch('UPLOADCARE_SECRET_KEY')
  )

  puts 'Step 1: Uploading files...'
  uuids = []

  file_paths.each_with_index do |path, index|
    uploaded = File.open(path, 'rb') do |file|
      client.files.upload(file, store: true)
    end

    uuids << uploaded.uuid
    puts "  #{index + 1}. #{File.basename(path)} → #{uploaded.uuid}"
  end

  puts
  puts "✓ Uploaded #{uuids.length} files"
  puts

  puts 'Step 2: Creating group...'
  group = client.groups.create(uuids: uuids)

  puts '✓ Group created!'
  puts
  puts 'Group Details:'
  puts '-' * 50
  puts "Group ID: #{group.id}"
  puts "Files count: #{group.files_count}"
  puts "CDN URL: #{group.cdn_url}"
  puts "Created at: #{group.datetime_created}"
  puts

  puts 'Step 3: Retrieving group info...'
  info = client.groups.find(group_id: group.id)

  puts '✓ Group info retrieved'
  puts
  puts 'Files in group:'
  puts '-' * 50

  Array(info.files).each_with_index do |file, index|
    file_resource = Uploadcare::Resources::File.new(file, client)
    puts "#{index + 1}. #{file_resource.original_filename}"
    puts "   UUID: #{file_resource.uuid}"
    puts "   Size: #{(file_resource.size / 1024.0).round(2)} KB"
    puts "   URL: #{file_resource.cdn_url}"
    puts
  end

  puts 'Group URL:'
  puts group.cdn_url
  puts
  puts 'You can access individual files in the group:'
  puts "#{group.cdn_url}nth/0/"
  puts "#{group.cdn_url}nth/1/"
rescue StandardError => e
  puts "✗ Group creation failed: #{e.message}"
  exit 1
end
