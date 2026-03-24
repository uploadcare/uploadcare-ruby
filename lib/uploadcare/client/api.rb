# frozen_string_literal: true

# Access to the endpoint-parity REST and Upload API clients for one configuration.
class Uploadcare::Client::Api
  attr_reader :config

  # @param config [Uploadcare::Configuration]
  def initialize(config:)
    @config = config
  end

  # @return [Uploadcare::Api::Rest]
  def rest
    @rest ||= Uploadcare::Api::Rest.new(config: config)
  end

  # @return [Uploadcare::Api::Upload]
  def upload
    @upload ||= Uploadcare::Api::Upload.new(config: config)
  end
end
