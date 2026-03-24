# frozen_string_literal: true

# High-level add-on execution helpers scoped to a client instance.
class Uploadcare::Client::AddonsAccessor
  attr_reader :client

  # @param client [Uploadcare::Client]
  def initialize(client:)
    @client = client
  end

  # @param uuid [String]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::AddonExecution]
  def aws_rekognition_detect_labels(uuid:, request_options: {})
    Uploadcare::Resources::AddonExecution.aws_rekognition_detect_labels(
      uuid: uuid, client: client, request_options: request_options
    )
  end

  # @param request_id [String]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::AddonExecution]
  def aws_rekognition_detect_labels_status(request_id:, request_options: {})
    Uploadcare::Resources::AddonExecution.aws_rekognition_detect_labels_status(
      request_id: request_id, client: client, request_options: request_options
    )
  end

  # @param uuid [String]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::AddonExecution]
  def aws_rekognition_detect_moderation_labels(uuid:, request_options: {})
    Uploadcare::Resources::AddonExecution.aws_rekognition_detect_moderation_labels(
      uuid: uuid, client: client, request_options: request_options
    )
  end

  # @param request_id [String]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::AddonExecution]
  def aws_rekognition_detect_moderation_labels_status(request_id:, request_options: {})
    Uploadcare::Resources::AddonExecution.aws_rekognition_detect_moderation_labels_status(
      request_id: request_id, client: client, request_options: request_options
    )
  end

  # @param uuid [String]
  # @param params [Hash]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::AddonExecution]
  def uc_clamav_virus_scan(uuid:, params: {}, request_options: {})
    Uploadcare::Resources::AddonExecution.uc_clamav_virus_scan(
      uuid: uuid, params: params, client: client, request_options: request_options
    )
  end

  # @param request_id [String]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::AddonExecution]
  def uc_clamav_virus_scan_status(request_id:, request_options: {})
    Uploadcare::Resources::AddonExecution.uc_clamav_virus_scan_status(
      request_id: request_id, client: client, request_options: request_options
    )
  end

  # @param uuid [String]
  # @param params [Hash]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::AddonExecution]
  def remove_bg(uuid:, params: {}, request_options: {})
    Uploadcare::Resources::AddonExecution.remove_bg(
      uuid: uuid, params: params, client: client, request_options: request_options
    )
  end

  # @param request_id [String]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::AddonExecution]
  def remove_bg_status(request_id:, request_options: {})
    Uploadcare::Resources::AddonExecution.remove_bg_status(
      request_id: request_id, client: client, request_options: request_options
    )
  end
end
