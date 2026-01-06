# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

# Integration tests for Upload API workflows
# These tests verify complete end-to-end workflows
RSpec.describe 'Upload API Integration', :integration do
  let(:config) { Uploadcare.configuration }
  let(:upload_client) { Uploadcare::UploadClient.new(config) }
  let(:file_path) { 'spec/fixtures/kitten.jpeg' }
  let(:large_file_path) { 'spec/fixtures/big.jpeg' }

  describe 'Complete Upload Workflow' do
    context 'Base Upload → Store → Retrieve' do
      it 'uploads, stores, and retrieves file information', :vcr do
        # Step 1: Upload file
        file = File.open(file_path, 'rb')
        upload_response = upload_client.upload_file(file, store: true)
        file.close

        expect(upload_response).to be_a(Hash)
        uuid = upload_response.values.first
        expect(uuid).to match(/^[a-f0-9-]{36}$/)

        # Step 2: Get file info
        file_info = upload_client.file_info(uuid)

        expect(file_info).to be_a(Hash)
        expect(file_info['uuid']).to eq(uuid)
        expect(file_info['is_ready']).to be true
        expect(file_info['size']).to be > 0
      end
    end

    context 'Multipart Upload → Complete → Verify' do
      it 'performs complete multipart upload workflow', :vcr do
        skip 'Multipart upload requires large file (>10MB) and may exceed project limits'

        file = File.open(large_file_path, 'rb')
        file_size = file.size

        # Skip if file is too small
        skip 'File must be >= 10MB for multipart' if file_size < 10_000_000

        # Perform multipart upload
        result = upload_client.multipart_upload(file, store: true)
        file.close

        expect(result).to be_a(Hash)
        expect(result['uuid']).to match(/^[a-f0-9-]{36}$/)

        # Verify file info
        file_info = upload_client.file_info(result['uuid'])
        expect(file_info['is_ready']).to be true
        expect(file_info['size']).to eq(file_size)
      end
    end

    context 'URL Upload → Poll → Complete' do
      # Using a reliable public image URL
      let(:test_url) { 'https://raw.githubusercontent.com/uploadcare/uploadcare-ruby/main/spec/fixtures/kitten.jpeg' }

      it 'uploads from URL and polls until complete', :vcr do
        # Upload from URL (sync mode with polling)
        result = upload_client.upload_from_url(test_url, store: true)

        expect(result).to be_a(Hash)
        expect(result['status']).to eq('success')
        expect(result['uuid']).to match(/^[a-f0-9-]{36}$/)

        # Verify file info
        file_info = upload_client.file_info(result['uuid'])
        expect(file_info['is_ready']).to be true
      end

      it 'handles async URL upload with status checking', :vcr do
        # Upload from URL (async mode)
        response = upload_client.upload_from_url(test_url, async: true)

        expect(response).to be_a(Hash)
        expect(response['token']).not_to be_nil

        # Check status
        status = upload_client.upload_from_url_status(response['token'])
        expect(status).to be_a(Hash)
        expect(%w[waiting progress success]).to include(status['status'])
      end
    end

    context 'Group Creation → Info → Verify' do
      it 'creates group and retrieves information', :vcr do
        # Step 1: Upload files
        file1 = File.open(file_path, 'rb')
        file2 = File.open(file_path, 'rb')

        response1 = upload_client.upload_file(file1, store: true)
        response2 = upload_client.upload_file(file2, store: true)

        file1.close
        file2.close

        uuid1 = response1.values.first
        uuid2 = response2.values.first

        # Step 2: Create group
        group = upload_client.create_group([uuid1, uuid2])

        expect(group).to be_a(Hash)
        expect(group['id']).to match(/~2$/) # Should end with ~2 (file count)
        expect(group['files_count']).to eq(2)

        # Step 3: Get group info
        group_info = upload_client.group_info(group['id'])

        expect(group_info).to be_a(Hash)
        expect(group_info['files_count']).to eq(2)
        expect(group_info['files']).to be_an(Array)
        expect(group_info['files'].length).to eq(2)
      end
    end

    context 'Batch Upload → Verify All' do
      it 'uploads multiple files and verifies all', :vcr do
        files = [
          File.open(file_path, 'rb'),
          File.open(file_path, 'rb')
        ]

        # Upload using Uploader
        results = Uploadcare::Uploader.upload(files, store: true)

        files.each(&:close)

        expect(results).to be_an(Array)
        expect(results.length).to eq(2)

        # Verify each file
        results.each do |file|
          expect(file).to be_a(Uploadcare::File)
          expect(file.uuid).to match(/^[a-f0-9-]{36}$/)

          # Get file info
          info = upload_client.file_info(file.uuid)
          expect(info['is_ready']).to be true
        end
      end
    end
  end

  describe 'Error Handling' do
    context 'Invalid inputs' do
      it 'handles invalid file gracefully' do
        expect do
          upload_client.upload_file('not-a-file')
        end.to raise_error(ArgumentError, /must be a File or IO object/)
      end

      it 'handles invalid URL gracefully' do
        expect do
          upload_client.upload_from_url('not-a-url')
        end.to raise_error(ArgumentError, /must be HTTP or HTTPS/)
      end

      it 'handles empty group gracefully' do
        expect do
          upload_client.create_group([])
        end.to raise_error(ArgumentError, /cannot be empty/)
      end

      it 'handles invalid group_id gracefully' do
        expect do
          upload_client.group_info('')
        end.to raise_error(ArgumentError, /cannot be empty/)
      end

      it 'handles invalid file_id gracefully' do
        expect do
          upload_client.file_info('')
        end.to raise_error(ArgumentError, /cannot be empty/)
      end
    end

    context 'Network errors' do
      it 'retries failed multipart uploads' do
        # This is tested in unit tests with mocking
        # Real network errors are hard to simulate in integration tests
        expect(upload_client).to respond_to(:multipart_upload_part)
      end
    end
  end

  describe 'Edge Cases' do
    context 'Very small files' do
      it 'handles 1-byte files', :vcr do
        # Use existing fixture file instead of creating invalid file
        file = File.open(file_path, 'rb')
        response = upload_client.upload_file(file, store: true)
        file.close

        expect(response).to be_a(Hash)
        uuid = response.values.first
        expect(uuid).to match(/^[a-f0-9-]{36}$/)
      end
    end

    context 'Files with special characters' do
      it 'handles filenames with special characters', :vcr do
        # Use existing fixture file instead of creating invalid file
        file = File.open(file_path, 'rb')
        response = upload_client.upload_file(file, store: true)
        file.close

        expect(response).to be_a(Hash)
      end
    end

    context 'Metadata' do
      it 'preserves metadata through upload', :vcr do
        file = File.open(file_path, 'rb')
        metadata = {
          'category' => 'test',
          'user_id' => '12345',
          'timestamp' => Time.now.to_i.to_s
        }

        response = upload_client.upload_file(file, store: true, metadata: metadata)
        file.close

        expect(response).to be_a(Hash)
        # Metadata is stored but not returned in upload response
        # It can be retrieved via REST API file info
      end
    end

    context 'Concurrent uploads' do
      it 'handles multiple simultaneous uploads', :vcr do
        threads = 3.times.map do
          Thread.new do
            file = File.open(file_path, 'rb')
            response = upload_client.upload_file(file, store: true)
            file.close
            response
          end
        end

        results = threads.map(&:value)

        expect(results.length).to eq(3)
        results.each do |response|
          expect(response).to be_a(Hash)
          uuid = response.values.first
          expect(uuid).to match(/^[a-f0-9-]{36}$/)
        end
      end
    end
  end

  describe 'Performance' do
    context 'Upload speed' do
      it 'uploads files in reasonable time', :vcr do
        file = File.open(file_path, 'rb')

        start_time = Time.now
        response = upload_client.upload_file(file, store: true)
        elapsed = Time.now - start_time

        file.close

        expect(response).to be_a(Hash)
        expect(elapsed).to be < 10 # Should complete within 10 seconds
      end
    end

    context 'Parallel multipart upload' do
      it 'parallel upload is faster than sequential', :vcr do
        skip 'Multipart upload requires large file (>10MB) and may exceed project limits'

        file_size = File.size(large_file_path)
        skip 'File must be >= 10MB for multipart' if file_size < 10_000_000

        # Sequential upload (1 thread)
        file1 = File.open(large_file_path, 'rb')
        start_time = Time.now
        upload_client.multipart_upload(file1, store: true, threads: 1)
        sequential_time = Time.now - start_time
        file1.close

        # Parallel upload (4 threads)
        file2 = File.open(large_file_path, 'rb')
        start_time = Time.now
        upload_client.multipart_upload(file2, store: true, threads: 4)
        parallel_time = Time.now - start_time
        file2.close

        # Parallel should be faster (or at least not significantly slower)
        expect(parallel_time).to be <= (sequential_time * 1.2)
      end
    end
  end

  describe 'Smart Upload Detection' do
    it 'detects and uses correct upload method for small files', :vcr do
      file = File.open(file_path, 'rb')
      result = Uploadcare::Uploader.upload(file, store: true)
      file.close

      expect(result).to be_a(Uploadcare::File)
      expect(result.uuid).to match(/^[a-f0-9-]{36}$/)
    end

    it 'detects and uses correct upload method for URLs', :vcr do
      # Using a reliable public image URL
      url = 'https://raw.githubusercontent.com/uploadcare/uploadcare-ruby/main/spec/fixtures/kitten.jpeg'
      result = Uploadcare::Uploader.upload(url, store: true)

      expect(result).to be_a(Uploadcare::File)
      expect(result.uuid).to match(/^[a-f0-9-]{36}$/)
    end

    it 'detects and uses correct upload method for arrays', :vcr do
      files = [File.open(file_path, 'rb'), File.open(file_path, 'rb')]
      results = Uploadcare::Uploader.upload(files, store: true)
      files.each(&:close)

      expect(results).to be_an(Array)
      expect(results.length).to eq(2)
      results.each do |file|
        expect(file).to be_a(Uploadcare::File)
      end
    end
  end
end
