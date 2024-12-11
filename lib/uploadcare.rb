# frozen_string_literal: true

require 'zeitwerk'
require 'faraday'

# Ruby wrapper for Uploadcare API
#
# @see https://uploadcare.com/docs/api_reference
module Uploadcare
  @loader = Zeitwerk::Loader.for_gem
  @loader.collapse("#{__dir__}/uploadcare/resources")
  @loader.collapse("#{__dir__}/uploadcare/clients")
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
  end
end
