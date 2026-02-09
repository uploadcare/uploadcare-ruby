# frozen_string_literal: true

# Base class for all Uploadcare resource objects
#
# Provides common functionality for resource classes including:
# - Configuration management
# - Attribute assignment from API responses
# - Access to REST client
#
# @example Creating a custom resource
#   class MyResource < Uploadcare::BaseResource
#     attr_accessor :name, :value
#
#     def fetch
#       response = rest_client.get(path: '/my-endpoint/')
#       assign_attributes(response)
#       self
#     end
#   end
#
# @abstract Subclass and add resource-specific attributes and methods
class Uploadcare::BaseResource
  # @return [Uploadcare::Configuration] The configuration object for this resource
  attr_accessor :config

  # Initialize a new resource instance
  #
  # @param attributes [Hash] Initial attributes to assign to the resource
  # @param config [Uploadcare::Configuration] Configuration object (defaults to global config)
  # @return [Uploadcare::BaseResource] new resource instance
  def initialize(attributes = {}, config = Uploadcare.configuration)
    @config = config
    assign_attributes(attributes)
  end

  protected

  # Get a REST client instance for making API requests
  #
  # @return [Uploadcare::RestClient] REST client configured with this resource's config
  def rest_client
    @rest_client ||= Uploadcare::RestClient.new(config: @config)
  end

  private

  # Assign attributes from a hash to the resource
  #
  # Only assigns values for attributes that have a setter method defined.
  #
  # @param attributes [Hash] Hash of attribute names to values
  # @api private
  def assign_attributes(attributes)
    attributes.each do |key, value|
      setter = "#{key}="
      send(setter, value) if respond_to?(setter)
    end
  end
end
