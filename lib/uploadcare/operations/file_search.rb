# frozen_string_literal: true

# Executes a file search and builds its POST-aware paginated result.
class Uploadcare::Operations::FileSearch
  QUERY_OPTIONS = %i[limit offset include].freeze

  class << self
    def call(options:, client:, resource_class:, request_options: {})
      search_params, query_params = split_options(options)
      response = Uploadcare::Result.unwrap(
        client.api.rest.files.search(
          params: search_params, query: query_params, request_options: request_options
        )
      )

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

    private

    def split_options(options)
      body = options.dup
      query = QUERY_OPTIONS.to_h do |key|
        value = body.key?(key) ? body.delete(key) : body[key.to_s]
        body.delete(key.to_s)
        [key, value]
      end
      [body, query.compact]
    end
  end
end
