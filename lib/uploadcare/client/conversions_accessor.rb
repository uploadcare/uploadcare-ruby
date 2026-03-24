# frozen_string_literal: true

# Entry point for document and video conversion helpers on a client.
class Uploadcare::Client::ConversionsAccessor
  attr_reader :client

  # @param client [Uploadcare::Client]
  def initialize(client:)
    @client = client
  end

  # @return [Uploadcare::Client::DocumentConversionsAccessor]
  def documents
    @documents ||= Uploadcare::Client::DocumentConversionsAccessor.new(client: client)
  end

  # @return [Uploadcare::Client::VideoConversionsAccessor]
  def videos
    @videos ||= Uploadcare::Client::VideoConversionsAccessor.new(client: client)
  end
end
