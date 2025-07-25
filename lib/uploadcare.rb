# frozen_string_literal: true

require 'zeitwerk'
require 'faraday'
require_relative 'uploadcare/errors'

# Ruby wrapper for Uploadcare API
#
# @see https://uploadcare.com/docs/api_reference
module Uploadcare
  @loader = Zeitwerk::Loader.for_gem
  @loader.collapse("#{__dir__}/uploadcare/resources")
  @loader.collapse("#{__dir__}/uploadcare/clients")
  @loader.collapse("#{__dir__}/uploadcare/signed_url_generators")
  @loader.collapse("#{__dir__}/uploadcare/middleware")
  @loader.setup

  class << self
    def configure
      yield configuration if block_given?
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def eager_load!
      @loader.eager_load
    end

    def api(config = nil)
      Api.new(config || configuration)
    end

    # Create a new client instance with optional configuration
    def client(options = {})
      Client.new(options)
    end

    # Convenience method to build URLs
    def url_builder(source)
      UrlBuilder.new(source, configuration)
    end
  end
end
