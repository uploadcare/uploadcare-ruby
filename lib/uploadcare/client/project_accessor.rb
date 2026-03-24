# frozen_string_literal: true

# Project endpoint wrapper scoped to a client instance.
class Uploadcare::Client::ProjectAccessor
  attr_reader :client

  # @param client [Uploadcare::Client]
  def initialize(client:)
    @client = client
  end

  # @param request_options [Hash]
  # @return [Uploadcare::Resources::Project]
  def current(request_options: {})
    Uploadcare::Resources::Project.current(client: client, request_options: request_options)
  end
end
