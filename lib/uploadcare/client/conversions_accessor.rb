# frozen_string_literal: true

class Uploadcare::Client::ConversionsAccessor
  attr_reader :client

  def initialize(client:)
    @client = client
  end

  def documents
    @documents ||= Uploadcare::Client::DocumentConversionsAccessor.new(client: client)
  end

  def videos
    @videos ||= Uploadcare::Client::VideoConversionsAccessor.new(client: client)
  end
end
