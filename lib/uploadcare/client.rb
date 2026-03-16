# frozen_string_literal: true

# Primary entry point for interacting with the Uploadcare API.
#
# Each Client instance owns its own configuration and provides domain-scoped
# accessors for all API operations. Multiple clients can coexist for
# multi-account support.
#
# @example Basic usage
#   client = Uploadcare::Client.new(public_key: "pk", secret_key: "sk")
#   file = client.files.upload(File.open("photo.jpg"), store: true)
#   file = client.files.find(uuid: "file-uuid")
#   files = client.files.list(limit: 100)
#
# @example Multi-account
#   account_a = Uploadcare::Client.new(public_key: "a", secret_key: "x")
#   account_b = Uploadcare::Client.new(public_key: "b", secret_key: "y")
#
# @example Raw API access
#   client.api.rest.files.list(params: { limit: 10 })
#   client.api.upload.files.direct(file: file_obj)
module Uploadcare
  class Client
    # @return [Uploadcare::Configuration]
    attr_reader :config

    # Initialize a new Client.
    #
    # @param config [Uploadcare::Configuration, nil] Base configuration
    # @param options [Hash] Configuration overrides (public_key:, secret_key:, etc.)
    def initialize(config: nil, **options)
      base_config = config || Uploadcare.configuration
      @config = options.empty? ? base_config : base_config.with(**options)
    end

    # Create a new client with overridden configuration.
    #
    # @param options [Hash] Configuration overrides
    # @return [Uploadcare::Client]
    def with(**options)
      self.class.new(config: config, **options)
    end

    # --- Raw API access ---

    # Access the raw API layer for direct endpoint calls.
    #
    # @return [Uploadcare::Client::Api]
    def api
      @api ||= Api.new(config: config)
    end

    # --- Domain accessors (convenience layer) ---

    # File operations: upload, find, list, batch_store, batch_delete, copy.
    #
    # @return [Uploadcare::Client::FilesAccessor]
    def files
      @files ||= FilesAccessor.new(client: self)
    end

    # Group operations: create, find, list, delete.
    #
    # @return [Uploadcare::Client::GroupsAccessor]
    def groups
      @groups ||= GroupsAccessor.new(client: self)
    end

    # Upload operations: upload, upload_file, upload_from_url, upload_many.
    #
    # @return [Uploadcare::Operations::UploadRouter]
    def uploads
      @uploads ||= Uploadcare::Operations::UploadRouter.new(client: self)
    end

    # Project information.
    #
    # @return [Uploadcare::Client::ProjectAccessor]
    def project
      @project ||= ProjectAccessor.new(client: self)
    end

    # Webhook operations: list, create, update, delete.
    #
    # @return [Uploadcare::Client::WebhooksAccessor]
    def webhooks
      @webhooks ||= WebhooksAccessor.new(client: self)
    end

    # Add-on operations.
    #
    # @return [Uploadcare::Client::AddonsAccessor]
    def addons
      @addons ||= AddonsAccessor.new(client: self)
    end

    # File metadata operations.
    #
    # @return [Uploadcare::Client::FileMetadataAccessor]
    def file_metadata
      @file_metadata ||= FileMetadataAccessor.new(client: self)
    end

    # Conversion operations (documents and videos).
    #
    # @return [Uploadcare::Client::ConversionsAccessor]
    def conversions
      @conversions ||= ConversionsAccessor.new(client: self)
    end

    # --- Top-level convenience methods ---

    # Smart upload: routes to direct, multipart, URL, or batch upload.
    #
    # @param source [File, IO, String, Array] Upload source
    # @param options [Hash] Upload options
    # @return [Uploadcare::Resources::File, Array<Uploadcare::Resources::File>, Hash]
    def upload(source, request_options: {}, **options, &block)
      uploads.upload(source, request_options: request_options, **options, &block)
    end

    # --- Inner classes ---

    # Raw API accessor providing direct access to REST and Upload API clients.
    class Api
      attr_reader :config

      def initialize(config:)
        @config = config
      end

      # @return [Uploadcare::Api::Rest] REST API client
      def rest
        @rest ||= Uploadcare::Api::Rest.new(config: config)
      end

      # @return [Uploadcare::Api::Upload] Upload API client
      def upload
        @upload ||= Uploadcare::Api::Upload.new(config: config)
      end
    end

    # Domain accessor for file operations.
    class FilesAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def find(uuid:, params: {}, request_options: {})
        Uploadcare::Resources::File.find(
          uuid: uuid, params: params, client: client, request_options: request_options
        )
      end

      def list(request_options: {}, **options)
        Uploadcare::Resources::File.list(
          options: options, client: client, request_options: request_options
        )
      end

      def upload(source, request_options: {}, **options, &block)
        client.uploads.upload(source, request_options: request_options, **options, &block)
      end

      def upload_from_url(url, request_options: {}, **options)
        client.uploads.upload_from_url(url: url, request_options: request_options, **options)
      end

      def batch_store(uuids:, request_options: {})
        Uploadcare::Resources::File.batch_store(uuids: uuids, client: client, request_options: request_options)
      end

      def batch_delete(uuids:, request_options: {})
        Uploadcare::Resources::File.batch_delete(uuids: uuids, client: client, request_options: request_options)
      end

      def copy_to_local(source:, options: {}, request_options: {})
        Uploadcare::Resources::File.local_copy(
          source: source, options: options, client: client, request_options: request_options
        )
      end

      def copy_to_remote(source:, target:, options: {}, request_options: {})
        Uploadcare::Resources::File.remote_copy(
          source: source, target: target, options: options, client: client, request_options: request_options
        )
      end
    end

    # Domain accessor for group operations.
    class GroupsAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def create(uuids, request_options: {}, **options)
        Uploadcare::Resources::Group.create(
          uuids: uuids, client: client, request_options: request_options, **options
        )
      end

      def find(group_id:, request_options: {})
        Uploadcare::Resources::Group.find(group_id: group_id, client: client, request_options: request_options)
      end

      def list(request_options: {}, **params)
        Uploadcare::Resources::Group.list(params: params, client: client, request_options: request_options)
      end
    end

    # Domain accessor for project operations.
    class ProjectAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def current(request_options: {})
        Uploadcare::Resources::Project.current(client: client, request_options: request_options)
      end
    end

    # Domain accessor for webhook operations.
    class WebhooksAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def list(request_options: {})
        Uploadcare::Resources::Webhook.list(client: client, request_options: request_options)
      end

      def create(target_url:, request_options: {}, **options)
        Uploadcare::Resources::Webhook.create(
          target_url: target_url, client: client, request_options: request_options, **options
        )
      end

      def update(id:, request_options: {}, **options)
        Uploadcare::Resources::Webhook.update(id: id, client: client, request_options: request_options, **options)
      end

      def delete(target_url:, request_options: {})
        Uploadcare::Resources::Webhook.delete(target_url: target_url, client: client,
                                              request_options: request_options)
      end
    end

    # Domain accessor for add-on operations.
    class AddonsAccessor
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

    # Domain accessor for file metadata operations.
    class FileMetadataAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def index(uuid:, request_options: {})
        Uploadcare::Resources::FileMetadata.index(uuid: uuid, client: client, request_options: request_options)
      end

      def show(uuid:, key:, request_options: {})
        Uploadcare::Resources::FileMetadata.show(uuid: uuid, key: key, client: client,
                                                 request_options: request_options)
      end

      def update(uuid:, key:, value:, request_options: {})
        Uploadcare::Resources::FileMetadata.update(uuid: uuid, key: key, value: value, client: client,
                                                   request_options: request_options)
      end

      def delete(uuid:, key:, request_options: {})
        Uploadcare::Resources::FileMetadata.delete(uuid: uuid, key: key, client: client,
                                                   request_options: request_options)
      end
    end

    # Domain accessor for conversion operations.
    class ConversionsAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      # @return [DocumentConversionsAccessor]
      def documents
        @documents ||= DocumentConversionsAccessor.new(client: client)
      end

      # @return [VideoConversionsAccessor]
      def videos
        @videos ||= VideoConversionsAccessor.new(client: client)
      end
    end

    # Domain accessor for document conversions.
    class DocumentConversionsAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def convert(uuid:, format:, options: {}, request_options: {})
        Uploadcare::Resources::DocumentConversion.convert_document(
          params: { uuid: uuid, format: format }, options: options, client: client,
          request_options: request_options
        )
      end

      def status(token:, request_options: {})
        Uploadcare::Resources::DocumentConversion.new({}, client).fetch_status(
          token: token, request_options: request_options
        )
      end

      def info(uuid:, request_options: {})
        Uploadcare::Resources::DocumentConversion.new({}, client).info(
          uuid: uuid, request_options: request_options
        )
      end
    end

    # Domain accessor for video conversions.
    class VideoConversionsAccessor
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def convert(uuid:, format:, quality:, options: {}, request_options: {})
        Uploadcare::Resources::VideoConversion.convert(
          params: { uuid: uuid, format: format, quality: quality }, options: options, client: client,
          request_options: request_options
        )
      end

      def status(token:, request_options: {})
        Uploadcare::Resources::VideoConversion.new({}, client).fetch_status(
          token: token, request_options: request_options
        )
      end
    end
  end
end
