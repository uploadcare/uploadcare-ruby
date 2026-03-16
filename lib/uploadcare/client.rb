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
    attr_reader :config

    def initialize(config: nil, **options)
      base_config = config || Uploadcare.configuration
      @config = options.empty? ? base_config : base_config.with(**options)
    end

    def with(**options)
      self.class.new(config: config, **options)
    end

    def api
      @api ||= Api.new(config: config)
    end

    def files
      @files ||= FilesAccessor.new(client: self)
    end

    def groups
      @groups ||= GroupsAccessor.new(client: self)
    end

    def uploads
      @uploads ||= Uploadcare::Operations::UploadRouter.new(client: self)
    end

    def project
      @project ||= ProjectAccessor.new(client: self)
    end

    def webhooks
      @webhooks ||= WebhooksAccessor.new(client: self)
    end

    def addons
      @addons ||= AddonsAccessor.new(client: self)
    end

    def file_metadata
      @file_metadata ||= FileMetadataAccessor.new(client: self)
    end

    def conversions
      @conversions ||= ConversionsAccessor.new(client: self)
    end

    def upload(source, request_options: {}, **options, &block)
      uploads.upload(source, request_options: request_options, **options, &block)
    end
  end
end
