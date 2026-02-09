# frozen_string_literal: true

# Client for Uploadcare Add-Ons API.
class Uploadcare::AddonsClient < Uploadcare::RestClient
  # Executes AWS Rekognition Add-On for a given target
  # @param uuid [String] The UUID of the file to process
  # @return [Hash] The response containing the request ID
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionExecute
  def aws_rekognition_detect_labels(uuid:, request_options: {})
    body = { target: uuid }
    post(path: '/addons/aws_rekognition_detect_labels/execute/', params: body, headers: {},
         request_options: request_options)
  end

  # Retrieves the execution status of an AWS Rekognition label detection Add-On.
  # @param request_id [String] The unique request ID returned by the Add-On execution.
  # @return [Hash] The response containing the current status of the label detection process.
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionExecutionStatus
  def aws_rekognition_detect_labels_status(request_id:, request_options: {})
    params = { request_id: request_id }
    get(path: '/addons/aws_rekognition_detect_labels/execute/status/', params: params, headers: {},
        request_options: request_options)
  end

  # Executes AWS Rekognition Moderation Add-On for a given target
  # @param uuid [String] The UUID of the file to process
  # @return [Hash] The response containing the request ID
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionDetectModerationLabelsExecute
  def aws_rekognition_detect_moderation_labels(uuid:, request_options: {})
    post(path: '/addons/aws_rekognition_detect_moderation_labels/execute/', params: { target: uuid },
         headers: {}, request_options: request_options)
  end

  # Check AWS Rekognition Moderation execution status
  # @param request_id [String] The Request ID from the Add-On execution
  # @return [Hash] The response containing the status
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionDetectModerationLabelsExecutionStatus
  def aws_rekognition_detect_moderation_labels_status(request_id:, request_options: {})
    get(path: '/addons/aws_rekognition_detect_moderation_labels/execute/status/', params: { request_id: request_id },
        headers: {}, request_options: request_options)
  end

  # Executes ClamAV virus checking Add-On for a given target
  # @param uuid [String] The UUID of the file to process
  # @param params [Hash] Optional parameters for the Add-On
  # @return [Hash] The response containing the request ID
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/ucClamavVirusScanExecute
  def uc_clamav_virus_scan(uuid:, params: {}, request_options: {})
    body = { target: uuid }.merge(params)
    post(path: '/addons/uc_clamav_virus_scan/execute/', params: body, headers: {}, request_options: request_options)
  end

  # Checks the status of a ClamAV virus scan execution
  # @param request_id [String] The Request ID from the Add-On execution
  # @return [Hash] The response containing the status
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/ucClamavVirusScanExecutionStatus
  def uc_clamav_virus_scan_status(request_id:, request_options: {})
    get(path: '/addons/uc_clamav_virus_scan/execute/status/', params: { request_id: request_id }, headers: {},
        request_options: request_options)
  end

  # Executes remove.bg background image removal Add-On
  # @param uuid [String] The UUID of the file to process
  # @param params [Hash] Optional parameters for the Add-On execution
  # @return [Hash] The response containing the request ID
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/removeBgExecute
  def remove_bg(uuid:, params: {}, request_options: {})
    post(path: '/addons/remove_bg/execute/', params: { target: uuid, params: params }, headers: {},
         request_options: request_options)
  end

  # Check Remove.bg execution status
  # @param request_id [String] The Request ID from the Add-On execution
  # @return [Hash] The response containing the status and result
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/removeBgExecutionStatus
  def remove_bg_status(request_id:, request_options: {})
    get(path: '/addons/remove_bg/execute/status/', params: { request_id: request_id }, headers: {},
        request_options: request_options)
  end
end
