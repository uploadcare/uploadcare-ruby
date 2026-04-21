# frozen_string_literal: true

# Access to the endpoint-parity REST and Upload API clients for one configuration.
class Uploadcare::Client::Api
  attr_reader :config

  # @param config [Uploadcare::Configuration]
  def initialize(config:)
    @config = config
    @memo_mutex = Mutex.new
  end

  # @return [Uploadcare::Api::Rest]
  def rest
    memoized(:@rest) { Uploadcare::Api::Rest.new(config: config) }
  end

  # @return [Uploadcare::Api::Upload]
  def upload
    memoized(:@upload) { Uploadcare::Api::Upload.new(config: config) }
  end

  private

  def memoized(ivar)
    cached = instance_variable_get(ivar)
    return cached if cached

    @memo_mutex.synchronize do
      instance_variable_get(ivar) || instance_variable_set(ivar, yield)
    end
  end
end
