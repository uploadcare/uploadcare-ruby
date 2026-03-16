# frozen_string_literal: true

require_relative 'example_helper'

module ApiExamples::RunUploadExample
  module_function

  def call
    ApiExamples::ExampleHelper.run do |client|
      case File.basename($PROGRAM_NAME)
      when 'post_base.rb'
        run_base_upload(client)
      when 'post_from_url.rb'
        run_url_upload(client)
      when 'get_from_url_status.rb'
        response = ApiExamples::ExampleHelper.unwrap(
          client.api.upload.files.from_url(
            source_url: ApiExamples::ExampleHelper::SAMPLE_IMAGE_URL,
            async: true,
            store: true
          )
        )
        ApiExamples::ExampleHelper.unwrap(client.api.upload.files.from_url_status(token: response.fetch('token')))
      when 'get_info.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          ApiExamples::ExampleHelper.unwrap(client.api.upload.files.info(file_id: file.uuid))
        end
      when 'post_group.rb'
        ApiExamples::ExampleHelper.with_uploaded_files do |files|
          group = ApiExamples::ExampleHelper.unwrap(client.api.upload.groups.create(files: files.map(&:uuid)))
          group
        ensure
          ApiExamples::ExampleHelper.safe_delete_group(group)
        end
      when 'get_group_info.rb'
        ApiExamples::ExampleHelper.with_uploaded_group do |group, _files|
          ApiExamples::ExampleHelper.unwrap(client.api.upload.groups.info(group_id: group.id))
        end
      when 'post_multipart_start.rb'
        ApiExamples::ExampleHelper.with_multipart_session do |file, session|
          completed_file = ApiExamples::ExampleHelper.finish_multipart_upload(file: file, session: session)
          {
            'uuid' => session.fetch('uuid'),
            'parts' => session.fetch('parts').length,
            'completed_file' => completed_file.fetch('uuid')
          }
        end
      when 'put_multipart_part.rb'
        ApiExamples::ExampleHelper.with_multipart_session do |file, session|
          uploaded = ApiExamples::ExampleHelper.upload_multipart_part(file: file, session: session, index: 0)
          completed = ApiExamples::ExampleHelper.finish_multipart_upload(
            file: file,
            session: session,
            skip_indices: [0]
          )
          {
            'uuid' => session.fetch('uuid'),
            'uploaded_bytes' => uploaded,
            'completed_file' => completed.fetch('uuid')
          }
        end
      when 'post_multipart_complete.rb'
        ApiExamples::ExampleHelper.with_multipart_session do |file, session|
          ApiExamples::ExampleHelper.finish_multipart_upload(file: file, session: session)
        end
      else
        raise "No Upload API example mapped for #{File.basename($PROGRAM_NAME)}"
      end
    end
  end

  def run_base_upload(client)
    handle = File.open(ApiExamples::ExampleHelper.fixture_path('kitten.jpeg'), 'rb')
    response = ApiExamples::ExampleHelper.unwrap(client.api.upload.files.direct(file: handle, store: true))
    response
  ensure
    handle&.close
    if response
      file_uuid = ApiExamples::ExampleHelper.uploaded_uuid_from_base_response(response)
      ApiExamples::ExampleHelper.safe_delete_file(file_uuid)
    end
  end

  def run_url_upload(client)
    response = ApiExamples::ExampleHelper.unwrap(
      client.api.upload.files.from_url(source_url: ApiExamples::ExampleHelper::SAMPLE_IMAGE_URL, store: true)
    )
    response
  ensure
    ApiExamples::ExampleHelper.safe_delete_file(response['uuid']) if response && response['uuid']
  end
end

ApiExamples::RunUploadExample.call
