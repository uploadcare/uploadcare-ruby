# frozen_string_literal: true

require_relative 'example_helper'

module ApiExamples::RunUploadExample
  module_function

  def call
    ExampleHelper.run do |client|
      case File.basename($PROGRAM_NAME)
      when 'post_base.rb'
        run_base_upload(client)
      when 'post_from_url.rb'
        run_url_upload(client)
      when 'get_from_url_status.rb'
        response = ExampleHelper.unwrap(
          client.api.upload.files.from_url(source_url: ExampleHelper::SAMPLE_IMAGE_URL, async: true, store: true)
        )
        ExampleHelper.unwrap(client.api.upload.files.from_url_status(token: response.fetch('token')))
      when 'get_info.rb'
        ExampleHelper.with_uploaded_file do |file|
          ExampleHelper.unwrap(client.api.upload.files.info(file_id: file.uuid))
        end
      when 'post_group.rb'
        ExampleHelper.with_uploaded_files do |files|
          ExampleHelper.unwrap(client.api.upload.groups.create(files: files.map(&:uuid)))
        end
      when 'get_group_info.rb'
        ExampleHelper.with_uploaded_group do |group, _files|
          ExampleHelper.unwrap(client.api.upload.groups.info(group_id: group.id))
        end
      when 'post_multipart_start.rb'
        ExampleHelper.with_multipart_session do |file, session|
          {
            'uuid' => session.fetch('uuid'),
            'parts' => session.fetch('parts').length,
            'completed_file' => ExampleHelper.finish_multipart_upload(file: file, session: session).fetch('uuid')
          }
        end
      when 'put_multipart_part.rb'
        ExampleHelper.with_multipart_session do |file, session|
          uploaded = ExampleHelper.upload_multipart_part(file: file, session: session, index: 0)
          completed = ExampleHelper.finish_multipart_upload(file: file, session: session)
          {
            'uuid' => session.fetch('uuid'),
            'uploaded_bytes' => uploaded,
            'completed_file' => completed.fetch('uuid')
          }
        end
      when 'post_multipart_complete.rb'
        ExampleHelper.with_multipart_session do |file, session|
          ExampleHelper.finish_multipart_upload(file: file, session: session)
        end
      else
        raise "No Upload API example mapped for #{File.basename($PROGRAM_NAME)}"
      end
    end
  end

  def run_base_upload(client)
    handle = File.open(ExampleHelper.fixture_path('kitten.jpeg'), 'rb')
    response = ExampleHelper.unwrap(client.api.upload.files.direct(file: handle, store: true))
    response
  ensure
    handle&.close
    ExampleHelper.safe_delete_file(ExampleHelper.uploaded_uuid_from_base_response(response)) if response
  end

  def run_url_upload(client)
    response = ExampleHelper.unwrap(
      client.api.upload.files.from_url(source_url: ExampleHelper::SAMPLE_IMAGE_URL, store: true)
    )
    response
  ensure
    ExampleHelper.safe_delete_file(response['uuid']) if response && response['uuid']
  end
end

ApiExamples::RunUploadExample.call
