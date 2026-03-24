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
class Uploadcare::Client
  attr_reader :config

  # Build a client bound to a specific configuration.
  #
  # @param config [Uploadcare::Configuration, nil] Base configuration to clone
  # @param options [Hash] Per-client configuration overrides
  def initialize(config: nil, **options)
    base_config = config || Uploadcare.configuration
    @config = base_config.with(**options)
  end

  # Build a new client derived from this client.
  #
  # @param options [Hash] Configuration overrides
  # @return [Uploadcare::Client]
  def with(**options)
    self.class.new(config: config, **options)
  end

  # Access the raw endpoint-parity API.
  #
  # @return [Uploadcare::Client::Api]
  def api
    @api ||= Api.new(config: config)
  end

  # Access file operations and upload helpers.
  #
  # @return [Uploadcare::Client::FilesAccessor]
  def files
    @files ||= FilesAccessor.new(client: self)
  end

  # Access group operations.
  #
  # @return [Uploadcare::Client::GroupsAccessor]
  def groups
    @groups ||= GroupsAccessor.new(client: self)
  end

  # Access upload routing helpers.
  #
  # @return [Uploadcare::Operations::UploadRouter]
  def uploads
    @uploads ||= Uploadcare::Operations::UploadRouter.new(client: self)
  end

  # Access project operations.
  #
  # @return [Uploadcare::Client::ProjectAccessor]
  def project
    @project ||= ProjectAccessor.new(client: self)
  end

  # Access webhook operations.
  #
  # @return [Uploadcare::Client::WebhooksAccessor]
  def webhooks
    @webhooks ||= WebhooksAccessor.new(client: self)
  end

  # Access add-on execution helpers.
  #
  # @return [Uploadcare::Client::AddonsAccessor]
  def addons
    @addons ||= AddonsAccessor.new(client: self)
  end

  # Access file metadata operations.
  #
  # @return [Uploadcare::Client::FileMetadataAccessor]
  def file_metadata
    @file_metadata ||= FileMetadataAccessor.new(client: self)
  end

  # Access conversion helpers.
  #
  # @return [Uploadcare::Client::ConversionsAccessor]
  def conversions
    @conversions ||= ConversionsAccessor.new(client: self)
  end

  # Upload a source through the convenience upload router.
  #
  # @param source [IO, Array<IO>, String] File object, file array, or URL
  # @param request_options [Hash] Per-request HTTP options
  # @param options [Hash] Upload options
  # @yield [Hash] Multipart progress callback
  # @return [Uploadcare::Resources::File, Array<Uploadcare::Resources::File>, Hash]
  def upload(source, request_options: {}, **options, &block)
    uploads.upload(source, request_options: request_options, **options, &block)
  end
end
