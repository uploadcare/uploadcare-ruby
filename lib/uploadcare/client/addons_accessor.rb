# frozen_string_literal: true

class Uploadcare::Client::AddonsAccessor
  attr_reader :client

  def initialize(client:)
    @client = client
  end

  def aws_rekognition_detect_labels(uuid:, request_options: {})
    Uploadcare::Resources::AddonExecution.aws_rekognition_detect_labels(
      uuid: uuid, client: client, request_options: request_options
    )
  end

  def aws_rekognition_detect_labels_status(request_id:, request_options: {})
    Uploadcare::Resources::AddonExecution.aws_rekognition_detect_labels_status(
      request_id: request_id, client: client, request_options: request_options
    )
  end

  def aws_rekognition_detect_moderation_labels(uuid:, request_options: {})
    Uploadcare::Resources::AddonExecution.aws_rekognition_detect_moderation_labels(
      uuid: uuid, client: client, request_options: request_options
    )
  end

  def aws_rekognition_detect_moderation_labels_status(request_id:, request_options: {})
    Uploadcare::Resources::AddonExecution.aws_rekognition_detect_moderation_labels_status(
      request_id: request_id, client: client, request_options: request_options
    )
  end

  def uc_clamav_virus_scan(uuid:, params: {}, request_options: {})
    Uploadcare::Resources::AddonExecution.uc_clamav_virus_scan(
      uuid: uuid, params: params, client: client, request_options: request_options
    )
  end

  def uc_clamav_virus_scan_status(request_id:, request_options: {})
    Uploadcare::Resources::AddonExecution.uc_clamav_virus_scan_status(
      request_id: request_id, client: client, request_options: request_options
    )
  end

  def remove_bg(uuid:, params: {}, request_options: {})
    Uploadcare::Resources::AddonExecution.remove_bg(
      uuid: uuid, params: params, client: client, request_options: request_options
    )
  end

  def remove_bg_status(request_id:, request_options: {})
    Uploadcare::Resources::AddonExecution.remove_bg_status(
      request_id: request_id, client: client, request_options: request_options
    )
  end
end
