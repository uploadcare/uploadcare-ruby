# frozen_string_literal: true

# Entry point for document and video conversion helpers on a client.
class Uploadcare::Client::ConversionsAccessor
  attr_reader :client

  # @param client [Uploadcare::Client]
  def initialize(client:)
    @client = client
    @memo_mutex = Mutex.new
  end

  # @return [Uploadcare::Client::DocumentConversionsAccessor]
  def documents
    memoized(:@documents) { Uploadcare::Client::DocumentConversionsAccessor.new(client: client) }
  end

  # @return [Uploadcare::Client::VideoConversionsAccessor]
  def videos
    memoized(:@videos) { Uploadcare::Client::VideoConversionsAccessor.new(client: client) }
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
