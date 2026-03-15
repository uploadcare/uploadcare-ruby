# frozen_string_literal: true

require 'zeitwerk'
require 'faraday'

module Uploadcare
end

# CNAME generator
require_relative 'uploadcare/cname_generator'

# Ruby wrapper for Uploadcare API
#
# @see https://uploadcare.com/docs/api_reference
module Uploadcare
  @loader = Zeitwerk::Loader.for_gem
  @loader.collapse("#{__dir__}/uploadcare/resources")
  @loader.collapse("#{__dir__}/uploadcare/clients")
  @loader.setup

  class << self
    # Configure Uploadcare with a block.
    #
    # @yieldparam config [Uploadcare::Configuration] configuration instance
    # @return [void]
    def configure
      yield configuration if block_given?
    end

    # Returns the global configuration instance.
    #
    # @return [Uploadcare::Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # Eager loads all Uploadcare classes for faster boot time.
    #
    # @return [void]
    def eager_load!
      @loader.eager_load
    end
  end
end
