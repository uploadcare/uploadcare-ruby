# frozen_string_literal: true

require_relative 'example_helper'

module ApiExamples::RunRestExample
  module_function

  def call
    ApiExamples::ExampleHelper.run do |client|
      case File.basename($PROGRAM_NAME)
      when 'get_project.rb'
        client.project.current
      when 'get_files.rb'
        client.files.list(limit: 2)
      when 'get_files_uuid.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          client.files.find(uuid: file.uuid)
        end
      when 'put_files_uuid_storage.rb'
        ApiExamples::ExampleHelper.with_uploaded_file(store: false, &:store)
      when 'delete_files_uuid_storage.rb'
        ApiExamples::ExampleHelper.with_uploaded_file(&:delete)
      when 'put_files_storage.rb'
        ApiExamples::ExampleHelper.with_uploaded_files(store: false) do |files|
          client.files.batch_store(uuids: files.map(&:uuid))
        end
      when 'delete_files_storage.rb'
        ApiExamples::ExampleHelper.with_uploaded_files do |files|
          client.files.batch_delete(uuids: files.map(&:uuid))
        end
      when 'post_files_local_copy.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          copied = client.files.copy_to_local(source: file.uuid, options: { store: true })
          copied
        ensure
          ApiExamples::ExampleHelper.safe_delete_file(copied)
        end
      when 'post_files_remote_copy.rb'
        target = ENV.fetch('UPLOADCARE_REMOTE_STORAGE', nil)
        if target.to_s.empty?
          ApiExamples::ExampleHelper.skip('Set UPLOADCARE_REMOTE_STORAGE to a configured custom storage name.')
        end
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          client.files.copy_to_remote(source: file.uuid, target: target)
        end
      when 'get_groups.rb'
        client.groups.list(limit: 2)
      when 'get_groups_uuid.rb'
        ApiExamples::ExampleHelper.with_uploaded_group do |group, _files|
          client.groups.find(group_id: group.id)
        end
      when 'delete_groups_uuid.rb'
        ApiExamples::ExampleHelper.with_uploaded_group do |group, _files|
          group.delete
        end
      when 'get_webhooks.rb'
        client.webhooks.list
      when 'post_webhooks.rb'
        ApiExamples::ExampleHelper.with_webhook do |webhook|
          {
            'id' => webhook.id,
            'target_url' => webhook.target_url,
            'is_active' => webhook.is_active,
            'event' => webhook.event
          }
        end
      when 'put_webhooks_id.rb'
        ApiExamples::ExampleHelper.with_webhook do |webhook|
          client.webhooks.update(id: webhook.id, is_active: false)
        end
      when 'delete_webhooks_unsubscribe.rb'
        ApiExamples::ExampleHelper.with_webhook do |webhook|
          client.webhooks.delete(target_url: webhook.target_url)
          { 'target_url' => webhook.target_url, 'deleted' => true }
        end
      when 'get_files_uuid_metadata.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          client.file_metadata.update(uuid: file.uuid, key: 'color', value: 'orange')
          client.file_metadata.index(uuid: file.uuid)
        end
      when 'get_files_uuid_metadata_key.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          client.file_metadata.update(uuid: file.uuid, key: 'color', value: 'orange')
          client.file_metadata.show(uuid: file.uuid, key: 'color')
        end
      when 'put_files_uuid_metadata_key.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          client.file_metadata.update(uuid: file.uuid, key: 'color', value: 'orange')
        end
      when 'delete_files_uuid_metadata_key.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          client.file_metadata.update(uuid: file.uuid, key: 'color', value: 'orange')
          client.file_metadata.delete(uuid: file.uuid, key: 'color')
          { 'uuid' => file.uuid, 'key' => 'color', 'deleted' => true }
        end
      when 'post_addons_aws_rekognition_detect_labels_execute.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          client.addons.aws_rekognition_detect_labels(uuid: file.uuid)
        end
      when 'get_addons_aws_rekognition_detect_labels_execute_status.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          response = client.addons.aws_rekognition_detect_labels(uuid: file.uuid)
          client.addons.aws_rekognition_detect_labels_status(request_id: response.request_id)
        end
      when 'post_addons_aws_rekognition_detect_moderation_labels_execute.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          client.addons.aws_rekognition_detect_moderation_labels(uuid: file.uuid)
        end
      when 'get_addons_aws_rekognition_detect_moderation_labels_execute_status.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          response = client.addons.aws_rekognition_detect_moderation_labels(uuid: file.uuid)
          client.addons.aws_rekognition_detect_moderation_labels_status(request_id: response.request_id)
        end
      when 'post_addons_uc_clamav_virus_scan_execute.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          client.addons.uc_clamav_virus_scan(uuid: file.uuid)
        end
      when 'get_addons_uc_clamav_virus_scan_execute_status.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          response = client.addons.uc_clamav_virus_scan(uuid: file.uuid)
          client.addons.uc_clamav_virus_scan_status(request_id: response.request_id)
        end
      when 'post_addons_remove_bg_execute.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          client.addons.remove_bg(uuid: file.uuid)
        end
      when 'get_addons_remove_bg_execute_status.rb'
        ApiExamples::ExampleHelper.with_uploaded_file do |file|
          response = client.addons.remove_bg(uuid: file.uuid)
          client.addons.remove_bg_status(request_id: response.request_id)
        end
      when 'get_convert_document_uuid.rb'
        ApiExamples::ExampleHelper.with_uploaded_pdf do |file|
          client.conversions.documents.info(uuid: file.uuid)
        end
      when 'post_convert_document.rb'
        ApiExamples::ExampleHelper.with_uploaded_pdf do |file|
          client.conversions.documents.convert(uuid: file.uuid, format: :jpg)
        end
      when 'get_convert_document_status_token.rb'
        ApiExamples::ExampleHelper.with_uploaded_pdf do |file|
          response = client.conversions.documents.convert(uuid: file.uuid, format: :jpg)
          client.conversions.documents.status(token: ApiExamples::ExampleHelper.conversion_token(response))
        end
      when 'post_convert_video.rb'
        ApiExamples::ExampleHelper.with_uploaded_video do |file|
          client.conversions.videos.convert(uuid: file.uuid, format: :webm, quality: :normal)
        end
      when 'get_convert_video_status_token.rb'
        ApiExamples::ExampleHelper.with_uploaded_video do |file|
          response = client.conversions.videos.convert(uuid: file.uuid, format: :webm, quality: :normal)
          client.conversions.videos.status(token: ApiExamples::ExampleHelper.conversion_token(response))
        end
      else
        raise "No REST API example mapped for #{File.basename($PROGRAM_NAME)}"
      end
    end
  end
end

ApiExamples::RunRestExample.call
