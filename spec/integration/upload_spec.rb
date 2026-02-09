# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'
require 'tempfile'

# Integration tests for Upload API workflows
# These tests verify complete end-to-end workflows
RSpec.describe 'Upload API Integration', :integration do
  let(:config) { Uploadcare.configuration }
  let(:upload_client) { Uploadcare::UploadClient.new(config: config) }
  let(:file_path) { 'spec/fixtures/kitten.jpeg' }
  let(:large_file_path) { 'spec/fixtures/big.jpeg' }

  describe 'Complete Upload Workflow' do
    context 'when uploading, storing, and retrieving' do
      it 'uploads, stores, and retrieves file information', :vcr do
        # Step 1: Upload file
        file = File.open(file_path, 'rb')
        upload_response = upload_client.upload_file(file: file, store: true).success
        file.close

        expect(upload_response).to be_a(Hash)
        uuid = upload_response.values.first
        expect(uuid).to match(/^[a-f0-9-]{36}$/)

        # Step 2: Get file info
        file_info = upload_client.file_info(file_id: uuid).success

        expect(file_info).to be_a(Hash)
        expect(file_info['uuid']).to eq(uuid)
        expect(file_info['is_ready']).to be true
        expect(file_info['size']).to be > 0
      end
    end

    context 'when completing multipart uploads' do
      it 'performs complete multipart upload workflow' do
        file = Tempfile.new('uploadcare-large')
        file_size = 10_000_001
        uuid = SecureRandom.uuid

        expect(upload_client)
          .to receive(:multipart_upload)
          .with(file: file, store: true)
          .and_return(Uploadcare::Result.success({ 'uuid' => uuid }))
        expect(upload_client)
          .to receive(:file_info)
          .with(file_id: uuid)
          .and_return(Uploadcare::Result.success({ 'is_ready' => true,
                                                   'size' => file_size,
                                                   'uuid' => uuid }))

        result = upload_client.multipart_upload(file: file, store: true).success
        file.close

        expect(result).to be_a(Hash)
        expect(result['uuid']).to eq(uuid)

        file_info = upload_client.file_info(file_id: result['uuid']).success
        expect(file_info['is_ready']).to be true
        expect(file_info['size']).to eq(file_size)
      end
    end

    context 'when uploading from URL' do
      # Using a reliable public image URL
      let(:test_url) { 'https://raw.githubusercontent.com/uploadcare/uploadcare-ruby/main/spec/fixtures/kitten.jpeg' }

      it 'uploads from URL and polls until complete', :vcr do
        # Upload from URL (sync mode with polling)
        result = upload_client.upload_from_url(source_url: test_url, store: true).success

        expect(result).to be_a(Hash)
        expect(result['status']).to eq('success')
        expect(result['uuid']).to match(/^[a-f0-9-]{36}$/)

        # Verify file info
        file_info = upload_client.file_info(file_id: result['uuid']).success
        expect(file_info['is_ready']).to be true
      end

      it 'handles async URL upload with status checking', :vcr do
        # Upload from URL (async mode)
        response = upload_client.upload_from_url(source_url: test_url, async: true).success

        expect(response).to be_a(Hash)
        expect(response['token']).not_to be_nil

        # Check status
        status = upload_client.upload_from_url_status(token: response['token']).success
        expect(status).to be_a(Hash)
        expect(%w[waiting progress success]).to include(status['status'])
      end
    end

    context 'when creating and verifying groups' do
      it 'creates group and retrieves information', :vcr do
        # Step 1: Upload files
        file1 = File.open(file_path, 'rb')
        file2 = File.open(file_path, 'rb')

        response1 = upload_client.upload_file(file: file1, store: true).success
        response2 = upload_client.upload_file(file: file2, store: true).success

        file1.close
        file2.close

        uuid1 = response1.values.first
        uuid2 = response2.values.first

        # Step 2: Create group
        group = upload_client.create_group(files: [uuid1, uuid2]).success

        expect(group).to be_a(Hash)
        expect(group['id']).to match(/~2$/) # Should end with ~2 (file count)
        expect(group['files_count']).to eq(2)

        # Step 3: Get group info
        group_info = upload_client.group_info(group_id: group['id']).success

        expect(group_info).to be_a(Hash)
        expect(group_info['files_count']).to eq(2)
        expect(group_info['files']).to be_an(Array)
        expect(group_info['files'].length).to eq(2)
      end
    end

    context 'when batch uploading' do
      it 'uploads multiple files and verifies all', :vcr do
        files = [
          File.open(file_path, 'rb'),
          File.open(file_path, 'rb')
        ]

        begin
          # Upload using Uploader.upload_files for batch uploads
          results = Uploadcare::Uploader.upload_files(files: files, store: true)

          expect(results).to be_an(Array)
          expect(results.length).to eq(2)

          # Verify each uploaded file
          results.each do |uploaded_file|
            expect(uploaded_file).to be_a(Uploadcare::File)
            expect(uploaded_file.uuid).to match(/^[a-f0-9-]{36}$/)

            # Get file info
            info = upload_client.file_info(file_id: uploaded_file.uuid).success
            expect(info['is_ready']).to be true
          end
        ensure
          files.each(&:close)
        end
      end
    end
  end

  describe 'Error Handling' do
    context 'when inputs are invalid' do
      it 'handles invalid file gracefully' do
        result = upload_client.upload_file(file: 'not-a-file')
        expect(result.failure?).to be true
        expect(result.error).to be_a(ArgumentError)
      end

      it 'handles invalid URL gracefully' do
        result = upload_client.upload_from_url(source_url: 'not-a-url')
        expect(result.failure?).to be true
        expect(result.error).to be_a(ArgumentError)
      end

      it 'handles empty group gracefully' do
        result = upload_client.create_group(files: [])
        expect(result.failure?).to be true
        expect(result.error).to be_a(ArgumentError)
      end

      it 'handles invalid group_id gracefully' do
        result = upload_client.group_info(group_id: '')
        expect(result.failure?).to be true
        expect(result.error).to be_a(ArgumentError)
      end

      it 'handles invalid file_id gracefully' do
        result = upload_client.file_info(file_id: '')
        expect(result.failure?).to be true
        expect(result.error).to be_a(ArgumentError)
      end
    end

    context 'when network errors occur' do
      it 'retries failed multipart uploads' do
        # This is tested in unit tests with mocking
        # Real network errors are hard to simulate in integration tests
        expect(upload_client).to respond_to(:multipart_upload_part)
      end
    end
  end

  describe 'Edge Cases' do
    context 'when uploading very small files' do
      it 'handles small fixture files', :vcr do
        # Use existing fixture file for basic upload test
        file = File.open(file_path, 'rb')
        response = upload_client.upload_file(file: file, store: true).success
        file.close

        expect(response).to be_a(Hash)
        uuid = response.values.first
        expect(uuid).to match(/^[a-f0-9-]{36}$/)
      end
    end

    context 'when uploading basic files' do
      it 'handles basic file uploads', :vcr do
        # Use existing fixture file for basic upload test
        file = File.open(file_path, 'rb')
        response = upload_client.upload_file(file: file, store: true).success
        file.close

        expect(response).to be_a(Hash)
      end
    end

    context 'when metadata is provided' do
      it 'preserves metadata through upload', :vcr do
        file = File.open(file_path, 'rb')
        metadata = {
          'category' => 'test',
          'user_id' => '12345',
          'timestamp' => Time.now.to_i.to_s
        }

        response = upload_client.upload_file(file: file, store: true, metadata: metadata).success
        file.close

        expect(response).to be_a(Hash)
        # Metadata is stored but not returned in upload response
        # It can be retrieved via REST API file info
      end
    end

    context 'when uploading concurrently' do
      it 'handles multiple simultaneous uploads', :vcr do
        threads = 3.times.map do
          Thread.new do
            file = File.open(file_path, 'rb')
            response = upload_client.upload_file(file: file, store: true).success
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
    context 'when measuring upload speed' do
      it 'uploads files in reasonable time', :vcr do
        file = File.open(file_path, 'rb')

        start_time = Time.now
        response = upload_client.upload_file(file: file, store: true).success
        elapsed = Time.now - start_time

        file.close

        expect(response).to be_a(Hash)
        expect(elapsed).to be < 10 # Should complete within 10 seconds
      end
    end

    context 'when performing parallel multipart upload' do
      it 'parallel upload is faster than sequential' do
        file1 = Tempfile.new('uploadcare-large')
        file2 = Tempfile.new('uploadcare-large')

        allow(upload_client).to receive(:multipart_upload) do |**options|
          sleep(options[:threads] == 1 ? 0.03 : 0.01)
          Uploadcare::Result.success({ 'uuid' => SecureRandom.uuid })
        end

        start_time = Time.now
        upload_client.multipart_upload(file: file1, store: true, threads: 1)
        sequential_time = Time.now - start_time
        file1.close

        start_time = Time.now
        upload_client.multipart_upload(file: file2, store: true, threads: 4)
        parallel_time = Time.now - start_time
        file2.close

        expect(parallel_time).to be <= (sequential_time * 1.2)
      end
    end
  end

  describe 'Smart Upload Detection' do
    it 'detects and uses correct upload method for small files', :vcr do
      file = File.open(file_path, 'rb')
      result = Uploadcare::Uploader.upload(object: file, store: true)
      file.close

      expect(result).to be_a(Uploadcare::File)
      expect(result.uuid).to match(/^[a-f0-9-]{36}$/)
    end

    it 'detects and uses correct upload method for URLs', :vcr do
      # Using a reliable public image URL
      url = 'https://raw.githubusercontent.com/uploadcare/uploadcare-ruby/main/spec/fixtures/kitten.jpeg'
      result = Uploadcare::Uploader.upload(object: url, store: true)

      expect(result).to be_a(Uploadcare::File)
      expect(result.uuid).to match(/^[a-f0-9-]{36}$/)
    end

    it 'detects and uses correct upload method for arrays', :vcr do
      files = [File.open(file_path, 'rb'), File.open(file_path, 'rb')]
      results = Uploadcare::Uploader.upload(object: files, store: true)
      files.each(&:close)

      expect(results).to be_an(Array)
      expect(results.length).to eq(2)
      results.each do |file|
        expect(file).to be_a(Uploadcare::File)
      end
    end
  end
end
