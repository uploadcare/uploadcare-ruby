# frozen_string_literal: true

module Uploadcare
  class AddOns < BaseResource
    attr_accessor :request_id, :status, :result

    class << self
      # Executes AWS Rekognition Add-On for a given target
      # @param uuid [String] The UUID of the file to process
      # @return [Uploadcare::AddOns] An instance of AddOns with the response data
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionExecute
      def aws_rekognition_detect_labels(uuid, config = Uploadcare.configuration)
        response = add_ons_client(config).aws_rekognition_detect_labels(uuid)
        new(response, config)
      end

      # Check AWS Rekognition execution status
      # @param request_id [String] The Request ID from the Add-On execution
      # @return [Uploadcare::AddOns] An instance of AddOns with the status data
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionExecutionStatus
      def aws_rekognition_detect_labels_status(request_id, config = Uploadcare.configuration)
        response = add_ons_client(config).aws_rekognition_detect_labels_status(request_id)
        new(response, config)
      end

      # Executes AWS Rekognition Moderation Add-On for a given target
      # @param uuid [String] The UUID of the file to process
      # @return [Uploadcare::AddOns] An instance of AddOns with the response data
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionDetectModerationLabelsExecute
      def aws_rekognition_detect_moderation_labels(uuid, config = Uploadcare.configuration)
        response = add_ons_client(config).aws_rekognition_detect_moderation_labels(uuid)
        new(response, config)
      end

      # Check AWS Rekognition Moderation execution status
      # @param request_id [String] The Request ID from the Add-On execution
      # @return [Uploadcare::AddOns] An instance of AddOns with the status data
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionDetectModerationLabelsExecutionStatus
      def aws_rekognition_detect_moderation_labels_status(request_id, config = Uploadcare.configuration)
        response = add_ons_client(config).aws_rekognition_detect_moderation_labels_status(request_id)
        new(response, config)
      end

      # Executes ClamAV virus checking Add-On
      # @param uuid [String] The UUID of the file to process
      # @param params [Hash] Optional parameters for the Add-On
      # @return [Uploadcare::AddOns] An instance of AddOns with the response data
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/ucClamavVirusScanExecute
      def uc_clamav_virus_scan(uuid, params = {}, config = Uploadcare.configuration)
        response = add_ons_client(config).uc_clamav_virus_scan(uuid, params)
        new(response, config)
      end

      # Checks the status of a ClamAV virus scan execution
      # @param request_id [String] The Request ID from the Add-On execution
      # @return [Uploadcare::AddOns] An instance of AddOns with the status data
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/ucClamavVirusScanExecutionStatus
      def uc_clamav_virus_scan_status(request_id, config = Uploadcare.configuration)
        response = add_ons_client(config).uc_clamav_virus_scan_status(request_id)
        new(response, config)
      end

      # Executes remove.bg Add-On for a given target
      # @param uuid [String] The UUID of the file to process
      # @param params [Hash] Optional parameters for the Add-On execution
      # @return [Uploadcare::AddOns] An instance of AddOns with the request ID
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/removeBgExecute
      def remove_bg(uuid, params = {}, config = Uploadcare.configuration)
        response = add_ons_client(config).remove_bg(uuid, params)
        new(response, config)
      end

      # Check Remove.bg Add-On execution status
      # @param request_id [String] The Request ID from the Add-On execution
      # @return [Uploadcare::AddOns] An instance of AddOns with the status and result
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/removeBgExecutionStatus
      def remove_bg_status(request_id, config = Uploadcare.configuration)
        response = add_ons_client(config).remove_bg_status(request_id)
        new(response, config)
      end

      private

      def add_ons_client(config)
        @add_ons_client ||= Uploadcare::AddOnsClient.new(config)
      end
    end
  end
end
