# frozen_string_literal: true

module Uploadcare
  class AddOnsClient < RestClient
    # Executes AWS Rekognition Add-On for a given target
    # @param uuid [String] The UUID of the file to process
    # @return [Hash] The response containing the request ID
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionExecute
    def aws_rekognition_detect_labels(uuid)
      body = { target: uuid }
      post('/addons/aws_rekognition_detect_labels/execute/', body)
    end

    # Retrieves the execution status of an AWS Rekognition label detection Add-On.
    # @param request_id [String] The unique request ID returned by the Add-On execution.
    # @return [Hash] The response containing the current status of the label detection process.
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionExecutionStatus
    def aws_rekognition_detect_labels_status(request_id)
      params = { request_id: request_id }
      get('/addons/aws_rekognition_detect_labels/execute/status/', params)
    end

    # Executes AWS Rekognition Moderation Add-On for a given target
    # @param uuid [String] The UUID of the file to process
    # @return [Hash] The response containing the request ID
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionDetectModerationLabelsExecute
    def aws_rekognition_detect_moderation_labels(uuid)
      post('/addons/aws_rekognition_detect_moderation_labels/execute/', { target: uuid })
    end

    # Check AWS Rekognition Moderation execution status
    # @param request_id [String] The Request ID from the Add-On execution
    # @return [Hash] The response containing the status
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionDetectModerationLabelsExecutionStatus
    def aws_rekognition_detect_moderation_labels_status(request_id)
      get('/addons/aws_rekognition_detect_moderation_labels/execute/status/', { request_id: request_id })
    end

    # Executes ClamAV virus checking Add-On for a given target
    # @param uuid [String] The UUID of the file to process
    # @param params [Hash] Optional parameters for the Add-On
    # @return [Hash] The response containing the request ID
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/ucClamavVirusScanExecute
    def uc_clamav_virus_scan(uuid, params = {})
      body = { target: uuid }.merge(params)
      post('/addons/uc_clamav_virus_scan/execute/', body)
    end

    # Checks the status of a ClamAV virus scan execution
    # @param request_id [String] The Request ID from the Add-On execution
    # @return [Hash] The response containing the status
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/ucClamavVirusScanExecutionStatus
    def uc_clamav_virus_scan_status(request_id)
      get('/addons/uc_clamav_virus_scan/execute/status/', { request_id: request_id })
    end

    # Executes remove.bg background image removal Add-On
    # @param uuid [String] The UUID of the file to process
    # @param params [Hash] Optional parameters for the Add-On execution
    # @return [Hash] The response containing the request ID
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/removeBgExecute
    def remove_bg(uuid, params = {})
      post('/addons/remove_bg/execute/', { target: uuid, params: params })
    end

    # Check Remove.bg execution status
    # @param request_id [String] The Request ID from the Add-On execution
    # @return [Hash] The response containing the status and result
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/removeBgExecutionStatus
    def remove_bg_status(request_id)
      get('/addons/remove_bg/execute/status/', { request_id: request_id })
    end
  end
end
