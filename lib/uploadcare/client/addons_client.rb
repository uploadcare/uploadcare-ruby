# frozen_string_literal: true

require_relative 'rest_client'

module Uploadcare
  module Client
    # API client for handling uploaded files
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons
    class AddonsClient < RestClient
      # Execute ClamAV virus checking Add-On for a given target.
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/awsRekognitionExecute
      def uc_clamav_virus_scan(uuid, **params)
        content = { target: uuid, params: params }.to_json
        post(uri: '/addons/uc_clamav_virus_scan/execute/', content: content)
      end

      # Check the status of an Add-On execution request that had been started using the Execute Add-On operation.
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/ucClamavVirusScanExecutionStatus
      def uc_clamav_virus_scan_status(uuid)
        get(uri: "/addons/uc_clamav_virus_scan/execute/status/#{query_params(uuid)}")
      end

      # Execute AWS Rekognition Add-On for a given target to detect labels in an image.
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/awsRekognitionExecute
      def ws_rekognition_detect_labels(uuid)
        content = { target: uuid }.to_json
        post(uri: '/addons/aws_rekognition_detect_labels/execute/', content: content)
      end

      # Check the status of an Add-On execution request that had been started using the Execute Add-On operation.
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/awsRekognitionExecutionStatus
      def ws_rekognition_detect_labels_status(uuid)
        get(uri: "/addons/aws_rekognition_detect_labels/execute/status/#{query_params(uuid)}")
      end

      # Execute remove.bg background image removal Add-On for a given target.
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/removeBgExecute
      def remove_bg(uuid, **params)
        content = { target: uuid, params: params }.to_json
        post(uri: '/addons/remove_bg/execute/', content: content)
      end

      # Check the status of an Add-On execution request that had been started using the Execute Add-On operation.
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/removeBgExecutionStatus
      def remove_bg_status(uuid)
        get(uri: "/addons/remove_bg/execute/status/#{query_params(uuid)}")
      end

      private

      def query_params(uuid)
        "?#{URI.encode_www_form(request_id: uuid)}"
      end
    end
  end
end
