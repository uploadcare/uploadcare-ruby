# frozen_string_literal: true

# Add-ons resource.
class Uploadcare::Addons < Uploadcare::BaseResource
  attr_accessor :request_id, :status, :result

  class << self
    # Executes AWS Rekognition Add-On for a given target
    # @param uuid [String] The UUID of the file to process
    # @return [Uploadcare::Addons] An instance of Addons with the response data
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionExecute
    def aws_rekognition_detect_labels(uuid:, config: Uploadcare.configuration, request_options: {})
      response = Uploadcare::Result.unwrap(
        addons_client(config).aws_rekognition_detect_labels(
          uuid: uuid,
          request_options: request_options
        )
      )
      new(response, config)
    end

    # Check AWS Rekognition execution status
    # @param request_id [String] The Request ID from the Add-On execution
    # @return [Uploadcare::Addons] An instance of Addons with the status data
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionExecutionStatus
    def aws_rekognition_detect_labels_status(request_id:, config: Uploadcare.configuration, request_options: {})
      response = Uploadcare::Result.unwrap(addons_client(config).aws_rekognition_detect_labels_status(
                                             request_id: request_id,
                                             request_options: request_options
                                           ))
      new(response, config)
    end

    # Executes AWS Rekognition Moderation Add-On for a given target
    # @param uuid [String] The UUID of the file to process
    # @return [Uploadcare::Addons] An instance of Addons with the response data
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionDetectModerationLabelsExecute
    def aws_rekognition_detect_moderation_labels(uuid:, config: Uploadcare.configuration, request_options: {})
      response = Uploadcare::Result.unwrap(addons_client(config).aws_rekognition_detect_moderation_labels(
                                             uuid: uuid,
                                             request_options: request_options
                                           ))
      new(response, config)
    end

    # Check AWS Rekognition Moderation execution status
    # @param request_id [String] The Request ID from the Add-On execution
    # @return [Uploadcare::Addons] An instance of Addons with the status data
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionDetectModerationLabelsExecutionStatus
    def aws_rekognition_detect_moderation_labels_status(request_id:, config: Uploadcare.configuration,
                                                        request_options: {})
      response = Uploadcare::Result.unwrap(addons_client(config).aws_rekognition_detect_moderation_labels_status(
                                             request_id: request_id,
                                             request_options: request_options
                                           ))
      new(response, config)
    end

    # Executes ClamAV virus checking Add-On
    # @param uuid [String] The UUID of the file to process
    # @param params [Hash] Optional parameters for the Add-On
    # @return [Uploadcare::Addons] An instance of Addons with the response data
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/ucClamavVirusScanExecute
    def uc_clamav_virus_scan(uuid:, params: {}, config: Uploadcare.configuration, request_options: {})
      response = Uploadcare::Result.unwrap(addons_client(config).uc_clamav_virus_scan(
                                             uuid: uuid,
                                             params: params,
                                             request_options: request_options
                                           ))
      new(response, config)
    end

    # Checks the status of a ClamAV virus scan execution
    # @param request_id [String] The Request ID from the Add-On execution
    # @return [Uploadcare::Addons] An instance of Addons with the status data
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/ucClamavVirusScanExecutionStatus
    def uc_clamav_virus_scan_status(request_id:, config: Uploadcare.configuration, request_options: {})
      response = Uploadcare::Result.unwrap(addons_client(config).uc_clamav_virus_scan_status(
                                             request_id: request_id,
                                             request_options: request_options
                                           ))
      new(response, config)
    end

    # Executes remove.bg Add-On for a given target
    # @param uuid [String] The UUID of the file to process
    # @param params [Hash] Optional parameters for the Add-On execution
    # @return [Uploadcare::Addons] An instance of Addons with the request ID
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/removeBgExecute
    def remove_bg(uuid:, params: {}, config: Uploadcare.configuration, request_options: {})
      response = Uploadcare::Result.unwrap(addons_client(config).remove_bg(
                                             uuid: uuid,
                                             params: params,
                                             request_options: request_options
                                           ))
      new(response, config)
    end

    # Check Remove.bg Add-On execution status
    # @param request_id [String] The Request ID from the Add-On execution
    # @return [Uploadcare::Addons] An instance of Addons with the status and result
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/removeBgExecutionStatus
    def remove_bg_status(request_id:, config: Uploadcare.configuration, request_options: {})
      response = Uploadcare::Result.unwrap(addons_client(config).remove_bg_status(
                                             request_id: request_id,
                                             request_options: request_options
                                           ))
      new(response, config)
    end

    private

    def addons_client(config)
      @addons_clients ||= {}
      @addons_clients[config] ||= Uploadcare::AddonsClient.new(config: config)
    end
  end
end
