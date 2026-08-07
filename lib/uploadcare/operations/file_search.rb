# frozen_string_literal: true

# Executes a file search and builds its POST-aware paginated result.
class Uploadcare::Operations::FileSearch
  QUERY_OPTIONS = %i[limit offset include].freeze

  def self.call(options:, client:, resource_class:, request_options: {})
    new(options: options, client: client, resource_class: resource_class, request_options: request_options).call
  end

  def initialize(options:, client:, resource_class:, request_options: {})
    @options = options
    @client = client
    @resource_class = resource_class
    @request_options = request_options
  end

  def call
    response = Uploadcare::Result.unwrap(
      client.api.rest.files.search(
        params: search_params, query: query_params, request_options: request_options
      )
    )

    build_result(response)
  end

  private

  attr_reader :client, :options, :request_options, :resource_class

  def search_params
    @search_params ||= split_options.first
  end

  def query_params
    @query_params ||= split_options.last
  end

  def split_options
    @split_options ||= begin
      body = options.dup
      query = QUERY_OPTIONS.to_h do |key|
        value = body.key?(key) ? body.delete(key) : body[key.to_s]
        body.delete(key.to_s)
        [key, value]
      end
      [body, query.compact]
    end
  end

  def build_result(response)
    Uploadcare::Collections::FileSearchResult.new(
      resources: response.fetch('results', []).map { |data| resource_class.new(data, client) },
      next_page: response['next'],
      previous_page: response['previous'],
      per_page: response['per_page'],
      total: response['total'],
      api_client: client.api.rest.files,
      resource_class: resource_class,
      client: client,
      request_options: request_options,
      search_params: search_params
    )
  end
end
