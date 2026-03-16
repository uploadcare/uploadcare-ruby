# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'stringio'

RSpec.describe Uploadcare::Operations::MultipartUpload do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple',
      multipart_chunk_size: 1024
    )
  end
  let(:upload_client) { instance_double(Uploadcare::Api::Upload) }
  let(:upload_files_api) { double('upload_files') }
  let(:uploader) { described_class.new(upload_client: upload_client, config: config) }

  before do
    allow(upload_client).to receive(:files).and_return(upload_files_api)
  end

  describe 'CHUNK_SIZE' do
    it 'equals 5MB' do
      expect(described_class::CHUNK_SIZE).to eq(5_242_880)
    end
  end

  describe '#initialize' do
    it 'stores upload_client' do
      expect(uploader.upload_client).to eq(upload_client)
    end

    it 'stores config' do
      expect(uploader.config).to eq(config)
    end
  end

  describe '#upload' do
    let(:file_content) { 'A' * 3072 } # 3KB — will need 3 parts with 1024 chunk size
    let(:tempfile) do
      f = Tempfile.new(['multipart_test', '.jpg'])
      f.binmode
      f.write(file_content)
      f.rewind
      f
    end
    let(:presigned_urls) do
      ['https://s3.example.com/part0', 'https://s3.example.com/part1', 'https://s3.example.com/part2']
    end
    let(:start_response) do
      { 'uuid' => 'mp-uuid-123', 'parts' => presigned_urls }
    end

    after { tempfile.close! }

    context 'when file is not a valid IO object' do
      it 'returns a failure Result with ArgumentError for a string' do
        result = uploader.upload(file: 'not-a-file')
        expect(result).to be_a(Uploadcare::Result)
        expect(result.failure?).to be(true)
        expect(result.error).to be_a(ArgumentError)
        expect(result.error.message).to include('readable IO object')
      end

      it 'returns a failure Result for an integer' do
        result = uploader.upload(file: 42)
        expect(result.failure?).to be(true)
        expect(result.error).to be_a(ArgumentError)
      end

      it 'returns a failure Result for nil' do
        result = uploader.upload(file: nil)
        expect(result.failure?).to be(true)
      end

      it 'accepts an object with read but no path by normalizing it to a temp file' do
        obj = StringIO.new(file_content)

        allow(upload_files_api).to receive(:multipart_start)
          .and_return(Uploadcare::Result.success(start_response))
        allow(upload_client).to receive(:upload_part_to_url)
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))

        result = uploader.upload(file: obj)
        expect(result.success?).to be(true)
        expect(result.value!).to eq({ 'uuid' => 'mp-uuid-123' })
      end
    end

    context 'when upload options are invalid' do
      it 'returns a failure Result when threads is less than 1' do
        result = uploader.upload(file: tempfile, threads: 0)

        expect(result.failure?).to be(true)
        expect(result.error).to be_a(ArgumentError)
        expect(result.error.message).to eq('threads must be >= 1')
      end

      it 'returns a failure Result when part_size is not positive' do
        result = uploader.upload(file: tempfile, part_size: 0)

        expect(result.failure?).to be(true)
        expect(result.error).to be_a(ArgumentError)
        expect(result.error.message).to eq('part_size must be > 0')
      end
    end

    context 'when performing sequential upload (threads <= 1)' do
      before do
        allow(upload_files_api).to receive(:multipart_start)
          .and_return(Uploadcare::Result.success(start_response))
        allow(upload_client).to receive(:upload_part_to_url)
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))
      end

      it 'returns a successful Result with the UUID' do
        result = uploader.upload(file: tempfile)
        expect(result).to be_a(Uploadcare::Result)
        expect(result.success?).to be(true)
        expect(result.value!).to eq({ 'uuid' => 'mp-uuid-123' })
      end

      it 'calls multipart_start with correct filename, size, and content_type' do
        expect(upload_files_api).to receive(:multipart_start).with(
          hash_including(
            filename: a_string_matching(/multipart_test.*\.jpg/),
            size: file_content.bytesize,
            content_type: 'image/jpeg'
          )
        ).and_return(Uploadcare::Result.success(start_response))

        uploader.upload(file: tempfile)
      end

      it 'uploads each part to its presigned URL' do
        expect(upload_client).to receive(:upload_part_to_url)
          .with('https://s3.example.com/part0', anything).ordered
        expect(upload_client).to receive(:upload_part_to_url)
          .with('https://s3.example.com/part1', anything).ordered
        expect(upload_client).to receive(:upload_part_to_url)
          .with('https://s3.example.com/part2', anything).ordered

        uploader.upload(file: tempfile)
      end

      it 'reads correct chunk sizes for each part' do
        chunks = []
        allow(upload_client).to receive(:upload_part_to_url) do |_url, data|
          chunks << data.bytesize
        end

        uploader.upload(file: tempfile)
        expect(chunks).to eq([1024, 1024, 1024])
      end

      it 'calls multipart_complete with the UUID' do
        expect(upload_files_api).to receive(:multipart_complete)
          .with(uuid: 'mp-uuid-123', request_options: {})
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))

        uploader.upload(file: tempfile)
      end

      it 'passes request_options through to start and complete' do
        opts = { timeout: 60 }
        expect(upload_files_api).to receive(:multipart_start)
          .with(hash_including(request_options: opts))
          .and_return(Uploadcare::Result.success(start_response))
        expect(upload_files_api).to receive(:multipart_complete)
          .with(uuid: 'mp-uuid-123', request_options: opts)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))

        uploader.upload(file: tempfile, request_options: opts)
      end

      it 'passes extra options (store, metadata) to multipart_start' do
        expect(upload_files_api).to receive(:multipart_start)
          .with(hash_including(store: true, metadata: { key: 'val' }))
          .and_return(Uploadcare::Result.success(start_response))

        uploader.upload(file: tempfile, store: true, metadata: { key: 'val' })
      end

      it 'uses custom part_size from options' do
        custom_config = Uploadcare::Configuration.new(
          public_key: 'pk', secret_key: 'sk', auth_type: 'Uploadcare.Simple',
          multipart_chunk_size: 2048
        )
        custom_uploader = described_class.new(upload_client: upload_client, config: custom_config)

        chunks = []
        allow(upload_files_api).to receive(:multipart_start)
          .and_return(Uploadcare::Result.success({
                                                   'uuid' => 'mp-uuid-123',
                                                   'parts' => ['https://s3.example.com/p0', 'https://s3.example.com/p1']
                                                 }))
        allow(upload_client).to receive(:upload_part_to_url) { |_url, data| chunks << data.bytesize }
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))

        custom_uploader.upload(file: tempfile, part_size: 512)
        expect(chunks.first).to eq(512)
      end

      it 'falls back to config.multipart_chunk_size when part_size not specified' do
        chunks = []
        allow(upload_client).to receive(:upload_part_to_url) { |_url, data| chunks << data.bytesize }

        uploader.upload(file: tempfile)
        expect(chunks.first).to eq(1024)
      end
    end

    context 'when reporting progress via block callback' do
      before do
        allow(upload_files_api).to receive(:multipart_start)
          .and_return(Uploadcare::Result.success(start_response))
        allow(upload_client).to receive(:upload_part_to_url)
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))
      end

      it 'calls the block for each uploaded part' do
        progress_calls = []
        uploader.upload(file: tempfile) { |p| progress_calls << p }

        expect(progress_calls.length).to eq(3)
      end

      it 'reports correct progress data for each part' do
        progress_calls = []
        uploader.upload(file: tempfile) { |p| progress_calls << p }

        expect(progress_calls[0]).to eq(uploaded: 1024, total: 3072, part: 1, total_parts: 3)
        expect(progress_calls[1]).to eq(uploaded: 2048, total: 3072, part: 2, total_parts: 3)
        expect(progress_calls[2]).to eq(uploaded: 3072, total: 3072, part: 3, total_parts: 3)
      end

      it 'works without a block (no error)' do
        expect { uploader.upload(file: tempfile) }.not_to raise_error
      end
    end

    context 'when performing parallel upload (threads > 1)' do
      before do
        allow(upload_files_api).to receive(:multipart_start)
          .and_return(Uploadcare::Result.success(start_response))
        allow(upload_client).to receive(:upload_part_to_url)
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))
      end

      it 'returns a successful Result' do
        result = uploader.upload(file: tempfile, threads: 2)
        expect(result.success?).to be(true)
        expect(result.value!).to eq({ 'uuid' => 'mp-uuid-123' })
      end

      it 'uploads all parts to presigned URLs' do
        uploaded_urls = []
        allow(upload_client).to receive(:upload_part_to_url) do |url, _data|
          uploaded_urls << url
        end

        uploader.upload(file: tempfile, threads: 2)
        expect(uploaded_urls.sort).to eq(presigned_urls.sort)
      end

      it 'uploads correct data chunks in parallel' do
        chunks = Mutex.new
        all_chunks = {}
        allow(upload_client).to receive(:upload_part_to_url) do |url, data|
          chunks.synchronize { all_chunks[url] = data.bytesize }
        end

        uploader.upload(file: tempfile, threads: 3)
        expect(all_chunks.values).to all(eq(1024))
        expect(all_chunks.size).to eq(3)
      end

      it 'reports progress via block callback' do
        progress_calls = []
        progress_mutex = Mutex.new

        uploader.upload(file: tempfile, threads: 2) do |p|
          progress_mutex.synchronize { progress_calls << p }
        end

        expect(progress_calls.length).to eq(3)
        progress_calls.each do |p|
          expect(p).to include(:uploaded, :total, :part, :total_parts)
          expect(p[:total]).to eq(3072)
          expect(p[:total_parts]).to eq(3)
        end
        final_uploaded = progress_calls.map { |p| p[:uploaded] }.max
        expect(final_uploaded).to eq(3072)
      end

      it 'works with more threads than parts' do
        result = uploader.upload(file: tempfile, threads: 10)
        expect(result.success?).to be(true)
      end

      it 'works with exactly 2 threads' do
        uploaded_urls = []
        allow(upload_client).to receive(:upload_part_to_url) do |url, _data|
          uploaded_urls << url
        end

        result = uploader.upload(file: tempfile, threads: 2)
        expect(result.success?).to be(true)
        expect(uploaded_urls.sort).to eq(presigned_urls.sort)
      end

      it 'raises error if a worker thread fails' do
        call_count = 0
        allow(upload_client).to receive(:upload_part_to_url) do |_url, _data|
          call_count += 1
          raise StandardError, 'S3 upload failed' if call_count == 2
        end

        result = uploader.upload(file: tempfile, threads: 2)
        expect(result.failure?).to be(true)
        expect(result.error.message).to include('S3 upload failed')
      end

      it 'propagates the first error from parallel workers' do
        allow(upload_client).to receive(:upload_part_to_url) do
          raise 'network timeout'
        end

        result = uploader.upload(file: tempfile, threads: 3)
        expect(result.failure?).to be(true)
        expect(result.error).to be_a(RuntimeError)
      end
    end

    context 'when file does not respond to #size' do
      it 'falls back to ::File.size(file.path)' do
        file_obj = Class.new do
          attr_reader :path

          def initialize(path, content)
            @path = path
            @content = content
            @pos = 0
          end

          def read(length = nil)
            return nil if @pos >= @content.bytesize

            data = length ? @content[@pos, length] : @content[@pos..]
            @pos += data.bytesize
            data
          end

          def seek(pos)
            @pos = pos
          end
        end.new(tempfile.path, file_content)

        allow(upload_files_api).to receive(:multipart_start) do |args|
          expect(args[:size]).to eq(File.size(tempfile.path))
          Uploadcare::Result.success(start_response)
        end
        allow(upload_client).to receive(:upload_part_to_url)
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))

        result = uploader.upload(file: file_obj)
        expect(result.success?).to be(true)
      end
    end

    context 'when file responds to #original_filename' do
      it 'uses original_filename instead of basename' do
        file_obj = Class.new do
          attr_reader :path, :original_filename

          def initialize(path, size)
            @path = path
            @original_filename = 'user_avatar.png'
            @size = size
          end

          def read(_length = nil) = 'data'
          def seek(_pos) = nil
          attr_reader :size
        end.new(tempfile.path, file_content.bytesize)

        allow(upload_files_api).to receive(:multipart_start) do |args|
          expect(args[:filename]).to eq('user_avatar.png')
          Uploadcare::Result.success(start_response)
        end
        allow(upload_client).to receive(:upload_part_to_url)
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))

        result = uploader.upload(file: file_obj)
        expect(result.success?).to be(true)
      end
    end

    context 'when file has unknown MIME type' do
      let(:unknown_file) do
        f = Tempfile.new(['test', '.xyz_unknown_ext'])
        f.binmode
        f.write('A' * 2048)
        f.rewind
        f
      end

      after { unknown_file.close! }

      it 'falls back to application/octet-stream' do
        allow(upload_files_api).to receive(:multipart_start) do |args|
          expect(args[:content_type]).to eq('application/octet-stream')
          Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123', 'parts' => ['https://s3.example.com/p0'] })
        end
        allow(upload_client).to receive(:upload_part_to_url)
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))

        result = uploader.upload(file: unknown_file)
        expect(result.success?).to be(true)
      end
    end

    context 'when multipart_start fails' do
      it 'returns a failure Result' do
        allow(upload_files_api).to receive(:multipart_start)
          .and_return(Uploadcare::Result.failure(StandardError.new('start failed')))

        result = uploader.upload(file: tempfile)
        expect(result.failure?).to be(true)
        expect(result.error.message).to include('start failed')
      end
    end

    context 'when multipart_complete fails' do
      it 'returns a failure Result' do
        allow(upload_files_api).to receive(:multipart_start)
          .and_return(Uploadcare::Result.success(start_response))
        allow(upload_client).to receive(:upload_part_to_url)
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.failure(StandardError.new('complete failed')))

        result = uploader.upload(file: tempfile)
        expect(result.failure?).to be(true)
        expect(result.error.message).to include('complete failed')
      end
    end

    context 'when upload_part_to_url raises during sequential upload' do
      it 'returns a failure Result' do
        allow(upload_files_api).to receive(:multipart_start)
          .and_return(Uploadcare::Result.success(start_response))
        allow(upload_client).to receive(:upload_part_to_url)
          .and_raise(Uploadcare::Exception::MultipartUploadError, 'part upload failed')

        result = uploader.upload(file: tempfile)
        expect(result.failure?).to be(true)
        expect(result.error).to be_a(Uploadcare::Exception::MultipartUploadError)
      end
    end

    context 'when presigned_urls has more URLs than needed for file size' do
      it 'stops uploading when read returns nil' do
        small_content = 'B' * 512
        small_file = Tempfile.new(['small', '.bin'])
        small_file.binmode
        small_file.write(small_content)
        small_file.rewind

        many_urls = 5.times.map { |i| "https://s3.example.com/part#{i}" }
        allow(upload_files_api).to receive(:multipart_start)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123', 'parts' => many_urls }))
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))

        uploaded_count = 0
        allow(upload_client).to receive(:upload_part_to_url) { uploaded_count += 1 }

        uploader.upload(file: small_file)
        expect(uploaded_count).to eq(1) # only 512 bytes < 1024 chunk, so 1 part

        small_file.close!
      end
    end

    context 'when performing parallel upload with offset >= total_size' do
      it 'handles more presigned URLs than needed' do
        small_content = 'C' * 1024
        small_file = Tempfile.new(['small_parallel', '.bin'])
        small_file.binmode
        small_file.write(small_content)
        small_file.rewind

        many_urls = 5.times.map { |i| "https://s3.example.com/part#{i}" }
        allow(upload_files_api).to receive(:multipart_start)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123', 'parts' => many_urls }))
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))

        uploaded_urls = []
        allow(upload_client).to receive(:upload_part_to_url) do |url, _data|
          uploaded_urls << url
        end

        result = uploader.upload(file: small_file, threads: 3)
        expect(result.success?).to be(true)
        expect(uploaded_urls.length).to eq(1)

        small_file.close!
      end
    end

    context 'when parallel worker encounters nil part_data' do
      it 'stops processing that worker gracefully' do
        allow(upload_files_api).to receive(:multipart_start)
          .and_return(Uploadcare::Result.success(start_response))
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))
        allow(upload_client).to receive(:upload_part_to_url)

        result = uploader.upload(file: tempfile, threads: 2)
        expect(result.success?).to be(true)
      end
    end

    context 'with a .png file extension' do
      let(:png_file) do
        f = Tempfile.new(['image', '.png'])
        f.binmode
        f.write('P' * 2048)
        f.rewind
        f
      end

      after { png_file.close! }

      it 'detects image/png content type' do
        allow(upload_files_api).to receive(:multipart_start) do |args|
          expect(args[:content_type]).to eq('image/png')
          Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123', 'parts' => ['https://s3.example.com/p0'] })
        end
        allow(upload_client).to receive(:upload_part_to_url)
        allow(upload_files_api).to receive(:multipart_complete)
          .and_return(Uploadcare::Result.success({ 'uuid' => 'mp-uuid-123' }))

        uploader.upload(file: png_file)
      end
    end
  end
end
