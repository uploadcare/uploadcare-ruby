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

    # @return [Uploadcare::Client::FilesAccessor]
    def files
      client.files
    end

    # @return [Uploadcare::Client::GroupsAccessor]
    def groups
      client.groups
    end

    # @return [Uploadcare::Operations::UploadRouter]
    def uploads
      client.uploads
    end

    # @return [Uploadcare::Client::ProjectAccessor]
    def project
      client.project
    end

    # Eager-load the gem namespace through Zeitwerk.
    #
    # @return [void]
    def eager_load!
      @loader.eager_load
    end
  end

  # Top-level aliases for the public resource classes.
  File = Resources::File
  # Alias for the group resource.
  Group = Resources::Group
  # Alias for the project resource.
  Project = Resources::Project
  # Alias for the webhook resource.
  Webhook = Resources::Webhook
  # Alias for the file metadata resource.
  FileMetadata = Resources::FileMetadata
  # Alias for the add-on execution resource.
  AddonExecution = Resources::AddonExecution
  # Alias for the document conversion resource.
  DocumentConversion = Resources::DocumentConversion
  # Alias for the video conversion resource.
  VideoConversion = Resources::VideoConversion
end
