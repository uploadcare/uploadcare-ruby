# frozen_string_literal: true

# Base class for signed URL generators.
class Uploadcare::SignedUrlGenerators::BaseGenerator
  attr_accessor :cdn_host, :ttl, :algorithm
  attr_reader :secret_key

  def initialize(cdn_host:, secret_key:, ttl: 300, algorithm: 'sha256')
    @ttl = ttl
    @algorithm = algorithm
    @cdn_host = cdn_host
    @secret_key = secret_key
  end

  # Generate a signed URL.
  #
  # @return [String]
  def generate_url
    raise NotImplementedError, "#{__method__} method not present"
  end
end
