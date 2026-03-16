# frozen_string_literal: true

# REST API endpoint for add-on operations.
#
# Supports AWS Rekognition (labels & moderation), ClamAV virus scan, and Remove.bg.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons
module Uploadcare
  module Api
    class Rest
      class Addons
        # @return [Uploadcare::Api::Rest] Parent REST client
        attr_reader :rest

        # @param rest [Uploadcare::Api::Rest] Parent REST client
        def initialize(rest:)
          @rest = rest
        end

        # Execute AWS Rekognition label detection.
        #
        # @param uuid [String] File UUID to process
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Hash with request_id
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionExecute
        def aws_rekognition_detect_labels(uuid:, request_options: {})
          rest.post(path: '/addons/aws_rekognition_detect_labels/execute/',
                    params: { target: uuid }, headers: {}, request_options: request_options)
        end

        # Check AWS Rekognition label detection status.
        #
        # @param request_id [String] Request ID from execution
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Hash with status
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionExecutionStatus
        def aws_rekognition_detect_labels_status(request_id:, request_options: {})
          rest.get(path: '/addons/aws_rekognition_detect_labels/execute/status/',
                   params: { request_id: request_id }, headers: {}, request_options: request_options)
        end

        # Execute AWS Rekognition moderation label detection.
        #
        # @param uuid [String] File UUID to process
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Hash with request_id
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionDetectModerationLabelsExecute
        def aws_rekognition_detect_moderation_labels(uuid:, request_options: {})
          rest.post(path: '/addons/aws_rekognition_detect_moderation_labels/execute/',
                    params: { target: uuid }, headers: {}, request_options: request_options)
        end

        # Check AWS Rekognition moderation label detection status.
        #
        # @param request_id [String] Request ID from execution
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Hash with status
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/awsRekognitionDetectModerationLabelsExecutionStatus
        def aws_rekognition_detect_moderation_labels_status(request_id:, request_options: {})
          rest.get(path: '/addons/aws_rekognition_detect_moderation_labels/execute/status/',
                   params: { request_id: request_id }, headers: {}, request_options: request_options)
        end

        # Execute ClamAV virus scan.
        #
        # @param uuid [String] File UUID to process
        # @param params [Hash] Optional scan parameters
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Hash with request_id
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/ucClamavVirusScanExecute
        def uc_clamav_virus_scan(uuid:, params: {}, request_options: {})
          body = { target: uuid }.merge(params)
          rest.post(path: '/addons/uc_clamav_virus_scan/execute/', params: body, headers: {},
                    request_options: request_options)
        end

        # Check ClamAV virus scan status.
        #
        # @param request_id [String] Request ID from execution
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Hash with status
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/ucClamavVirusScanExecutionStatus
        def uc_clamav_virus_scan_status(request_id:, request_options: {})
          rest.get(path: '/addons/uc_clamav_virus_scan/execute/status/',
                   params: { request_id: request_id }, headers: {}, request_options: request_options)
        end

        # Execute Remove.bg background removal.
        #
        # @param uuid [String] File UUID to process
        # @param params [Hash] Optional parameters for the add-on
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Hash with request_id
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/removeBgExecute
        def remove_bg(uuid:, params: {}, request_options: {})
          rest.post(path: '/addons/remove_bg/execute/',
                    params: { target: uuid, params: params }, headers: {}, request_options: request_options)
        end

        # Check Remove.bg execution status.
        #
        # @param request_id [String] Request ID from execution
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Hash with status and result
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons/operation/removeBgExecutionStatus
        def remove_bg_status(request_id:, request_options: {})
          rest.get(path: '/addons/remove_bg/execute/status/',
                   params: { request_id: request_id }, headers: {}, request_options: request_options)
        end
      end
    end
  end
end
