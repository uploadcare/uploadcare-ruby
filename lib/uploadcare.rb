# frozen_string_literal: true

require 'zeitwerk'
require 'faraday'

module Uploadcare
  @loader = Zeitwerk::Loader.for_gem

  @loader.setup

  require_relative 'uploadcare/cname_generator'

  class << self
    # Configure the global Uploadcare instance.
    #
    # @yield [config] Configuration block
    # @yieldparam config [Uploadcare::Configuration] The configuration object
    def configure
      yield configuration if block_given?
    ensure
      @client = nil
    end

    # Access the global configuration.
    #
    # @return [Uploadcare::Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # Access a global client instance, or create one with overrides.
    #
    # @param config [Uploadcare::Configuration, nil] Custom configuration
    # @param options [Hash] Configuration overrides
    # @return [Uploadcare::Client]
    def client(config: nil, **options)
      if options.empty? && (config.nil? || config.equal?(configuration))
        return (@client ||= Client.new(config: configuration))
      end

      Client.new(config: config || configuration, **options)
    end

    # Convenience accessor for files domain.
    #
    # @return [Uploadcare::Client::FilesAccessor]
    def files
      client.files
    end

    # Convenience accessor for groups domain.
    #
    # @return [Uploadcare::Client::GroupsAccessor]
    def groups
      client.groups
    end

    # Convenience accessor for uploads domain.
    #
    # @return [Uploadcare::Operations::UploadRouter]
    def uploads
      client.uploads
    end

    # Convenience accessor for project domain.
    #
    # @return [Uploadcare::Client::ProjectAccessor]
    def project
      client.project
    end

    def eager_load!
      @loader.eager_load
    end
  end

  # --- Public top-level constants (per blueprint compatibility policy) ---
  File = Resources::File
  Group = Resources::Group
  Project = Resources::Project
  Webhook = Resources::Webhook
  FileMetadata = Resources::FileMetadata
  AddonExecution = Resources::AddonExecution
  DocumentConversion = Resources::DocumentConversion
  VideoConversion = Resources::VideoConversion
end
