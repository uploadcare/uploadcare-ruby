# frozen_string_literal: true

# Base class for all Uploadcare resource objects.
#
# Resources represent domain objects returned by the Uploadcare API.
# They hold attributes and a reference to the client that created them,
# enabling instance methods to make further API calls.
class Uploadcare::Resources::BaseResource
  # @return [Uploadcare::Client] Client that created this resource
  attr_reader :client

  # @return [Uploadcare::Configuration] Configuration from the client
  attr_reader :config

  # Initialize a new resource with attributes and client context.
  #
  # @param attributes [Hash] API response attributes
  # @param client_or_config [Uploadcare::Client, Uploadcare::Configuration, nil]
  def initialize(attributes = {}, client_or_config = nil)
    @client = self.class.resolve_client(client_or_config)
    @config = @client.config
    assign_attributes(attributes)
  end

  protected

  # Assign hash attributes to instance variables via setter methods.
  #
  # @param attributes [Hash] Key-value pairs to assign
  def assign_attributes(attributes)
    attributes.each do |key, value|
      setter = "#{key}="
      public_send(setter, value) if respond_to?(setter)
    end
  end

  class << self
    # Resolve a client from various input types.
    #
    # @param client_or_config [Uploadcare::Client, Uploadcare::Configuration, nil]
    # @param client [Uploadcare::Client, nil] Explicit client
    # @param config [Uploadcare::Configuration] Configuration fallback
    # @return [Uploadcare::Client]
    def resolve_client(client_or_config = nil, client: nil, config: nil)
      return client if client

      case client_or_config
      when Uploadcare::Client
        client_or_config
      when Uploadcare::Configuration
        Uploadcare.client(config: client_or_config)
      when nil
        return Uploadcare.client(config: config) if config

        raise ArgumentError, 'client or config is required'
      else
        raise ArgumentError, 'client or config is required'
      end
    end
  end
end
