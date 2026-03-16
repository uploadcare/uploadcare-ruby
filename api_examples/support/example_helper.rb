# frozen_string_literal: true

require 'json'
require 'dotenv/load'
require 'tempfile'
require 'securerandom'

require_relative '../../lib/uploadcare'

module ApiExamples
end

module ApiExamples::ExampleHelper
  SAMPLE_IMAGE_URL = 'https://upload.wikimedia.org/wikipedia/commons/3/3f/JPEG_example_flower.jpg'
  SAMPLE_VIDEO_URL = 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4'

  module_function

  def client
    @client ||= Uploadcare::Client.new(
      public_key: ENV.fetch('UPLOADCARE_PUBLIC_KEY'),
      secret_key: ENV.fetch('UPLOADCARE_SECRET_KEY'),
      auth_type: ENV.fetch('UPLOADCARE_AUTH_TYPE', 'Uploadcare.Simple')
    )
  end

  def run
    output(yield(client))
  rescue StandardError => e
    warn("#{e.class}: #{e.message}")
    exit 1
  end

  def output(value)
    puts JSON.pretty_generate(value)
  end

  def unwrap(result)
    Uploadcare::Result.unwrap(result)
  end

  def skip(message)
    output('skipped' => true, 'reason' => message)
    exit 0
  end

  def fixture_path(name)
    File.expand_path("../../spec/fixtures/#{name}", __dir__)
  end

  def with_uploaded_file(path: fixture_path('kitten.jpeg'), store: true, metadata: {})
    handle = File.open(path, 'rb')
    file = client.files.upload(handle, store: store, metadata: metadata)
    yield file
  ensure
    handle&.close
    safe_delete_file(file)
  end

  def with_uploaded_files(paths: [fixture_path('kitten.jpeg'), fixture_path('another_kitten.jpeg')], store: true)
    handles = paths.map { |path| File.open(path, 'rb') }
    files = client.files.upload(handles, store: store)
    yield files
  ensure
    handles&.each(&:close)
    Array(files).each { |file| safe_delete_file(file) }
  end

  def with_uploaded_group
    with_uploaded_files do |files|
      group = client.groups.create(uuids: files.map(&:uuid))
      yield group, files
    ensure
      safe_delete_group(group)
    end
  end

  def with_webhook
    webhook = client.webhooks.create(
      target_url: "https://example.com/uploadcare-webhook/#{SecureRandom.hex(4)}",
      is_active: true
    )
    yield webhook
  ensure
    safe_delete_webhook(webhook)
  end

  def with_uploaded_pdf
    pdf = Tempfile.new(['uploadcare-example', '.pdf'])
    pdf.write(minimal_pdf)
    pdf.rewind
    file = client.files.upload(pdf, store: true)
    yield file
  ensure
    pdf&.close!
    safe_delete_file(file)
  end

  def with_uploaded_video
    file = client.files.upload_from_url(SAMPLE_VIDEO_URL, store: true)
    yield file
  ensure
    safe_delete_file(file)
  end

  def multipart_part_size
    5 * 1024 * 1024
  end

  def with_multipart_session
    file = File.open(fixture_path('big.jpeg'), 'rb')
    response = unwrap(
      client.api.upload.files.multipart_start(
        filename: File.basename(file.path),
        size: file.size,
        content_type: 'image/jpeg',
        part_size: multipart_part_size,
        store: true
      )
    )
    yield file, response
  ensure
    file&.close
  end

  def upload_multipart_part(file:, session:, index:)
    file.seek(index * multipart_part_size)
    data = file.read(multipart_part_size)
    return nil unless data && !data.empty?

    client.api.upload.upload_part_to_url(session.fetch('parts').fetch(index), data)
    data.bytesize
  end

  def finish_multipart_upload(file:, session:)
    session.fetch('parts').each_index do |index|
      upload_multipart_part(file: file, session: session, index: index)
    end
    unwrap(client.api.upload.files.multipart_complete(uuid: session.fetch('uuid')))
  end

  def uploaded_uuid_from_base_response(response)
    response.values.first
  end

  def conversion_token(response)
    result = if response.respond_to?(:result)
               response.result
             else
               response.fetch('result')
             end

    Array(result).first.fetch('token')
  end

  def safe_delete_file(file)
    return unless file

    uuid = if file.respond_to?(:uuid)
             file.uuid
           elsif file.is_a?(Hash)
             file['uuid'] || file[:uuid]
           else
             file
           end
    return if uuid.to_s.empty?

    client.api.rest.files.delete(uuid: uuid)
  rescue StandardError
    nil
  end

  def safe_delete_group(group)
    return unless group&.id

    client.api.rest.groups.delete(uuid: group.id)
  rescue StandardError
    nil
  end

  def safe_delete_webhook(webhook)
    return unless webhook&.target_url

    client.api.rest.webhooks.delete(target_url: webhook.target_url)
  rescue StandardError
    nil
  end

  def minimal_pdf
    <<~PDF
      %PDF-1.4
      1 0 obj
      << /Type /Catalog /Pages 2 0 R >>
      endobj
      2 0 obj
      << /Type /Pages /Kids [3 0 R] /Count 1 >>
      endobj
      3 0 obj
      << /Type /Page /Parent 2 0 R /MediaBox [0 0 300 144] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>
      endobj
      4 0 obj
      << /Length 44 >>
      stream
      BT
      /F1 18 Tf
      72 100 Td
      (Uploadcare PDF) Tj
      ET
      endstream
      endobj
      5 0 obj
      << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
      endobj
      xref
      0 6
      0000000000 65535 f
      0000000009 00000 n
      0000000058 00000 n
      0000000115 00000 n
      0000000241 00000 n
      0000000334 00000 n
      trailer
      << /Size 6 /Root 1 0 R >>
      startxref
      404
      %%EOF
    PDF
  end
end
