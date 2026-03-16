# frozen_string_literal: true

# Add-on execution resource.
#
# Provides a unified interface for executing and checking status of
# AWS Rekognition, ClamAV, and Remove.bg add-ons.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons
module Uploadcare
  module Resources
    class AddonExecution < BaseResource
      attr_accessor :request_id, :status, :result

      class << self
        # Execute AWS Rekognition label detection.
        def aws_rekognition_detect_labels(uuid:, client: nil, config: Uploadcare.configuration, request_options: {})
          execute_addon(:aws_rekognition_detect_labels, client: client, config: config,
                                                        request_options: request_options, uuid: uuid)
        end

        # Check AWS Rekognition label detection status.
        def aws_rekognition_detect_labels_status(request_id:, client: nil, config: Uploadcare.configuration,
                                                 request_options: {})
          check_addon_status(:aws_rekognition_detect_labels_status, client: client, config: config,
                                                                    request_options: request_options,
                                                                    request_id: request_id)
        end

        # Execute AWS Rekognition moderation label detection.
        def aws_rekognition_detect_moderation_labels(uuid:, client: nil, config: Uploadcare.configuration,
                                                     request_options: {})
          execute_addon(:aws_rekognition_detect_moderation_labels, client: client, config: config,
                                                                   request_options: request_options, uuid: uuid)
        end

        # Check AWS Rekognition moderation label detection status.
        def aws_rekognition_detect_moderation_labels_status(request_id:, client: nil,
                                                            config: Uploadcare.configuration, request_options: {})
          check_addon_status(:aws_rekognition_detect_moderation_labels_status, client: client, config: config,
                                                                              request_options: request_options,
                                                                              request_id: request_id)
        end

        # Execute ClamAV virus scan.
        def uc_clamav_virus_scan(uuid:, params: {}, client: nil, config: Uploadcare.configuration, request_options: {})
          resolved_client = resolve_client(client: client, config: config)
          response = Uploadcare::Result.unwrap(
            resolved_client.api.rest.addons.uc_clamav_virus_scan(
              uuid: uuid, params: params, request_options: request_options
            )
          )
          new(response, resolved_client)
        end

        # Check ClamAV virus scan status.
        def uc_clamav_virus_scan_status(request_id:, client: nil, config: Uploadcare.configuration,
                                        request_options: {})
          check_addon_status(:uc_clamav_virus_scan_status, client: client, config: config,
                                                           request_options: request_options, request_id: request_id)
        end

        # Execute Remove.bg background removal.
        def remove_bg(uuid:, params: {}, client: nil, config: Uploadcare.configuration, request_options: {})
          resolved_client = resolve_client(client: client, config: config)
          response = Uploadcare::Result.unwrap(
            resolved_client.api.rest.addons.remove_bg(
              uuid: uuid, params: params, request_options: request_options
            )
          )
          new(response, resolved_client)
        end

        # Check Remove.bg execution status.
        def remove_bg_status(request_id:, client: nil, config: Uploadcare.configuration, request_options: {})
          check_addon_status(:remove_bg_status, client: client, config: config,
                                                request_options: request_options, request_id: request_id)
        end

        private

        def execute_addon(method_name, client:, config:, request_options:, uuid:)
          resolved_client = resolve_client(client: client, config: config)
          response = Uploadcare::Result.unwrap(
            resolved_client.api.rest.addons.public_send(method_name, uuid: uuid, request_options: request_options)
          )
          new(response, resolved_client)
        end

        def check_addon_status(method_name, client:, config:, request_options:, request_id:)
          resolved_client = resolve_client(client: client, config: config)
          response = Uploadcare::Result.unwrap(
            resolved_client.api.rest.addons.public_send(
              method_name, request_id: request_id, request_options: request_options
            )
          )
          new(response, resolved_client)
        end
      end
    end
  end
end
