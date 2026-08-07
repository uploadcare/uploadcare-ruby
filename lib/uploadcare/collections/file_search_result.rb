# frozen_string_literal: true

# Paginated results returned by the file search endpoint.
#
# Search pagination uses POST requests, so every subsequent page must resend the
# original JSON search criteria while following the query parameters supplied by
# the API's next or previous URL.
class Uploadcare::Collections::FileSearchResult < Uploadcare::Collections::Paginated
  # @return [Hash] JSON search criteria resent for subsequent pages
  attr_reader :search_params

  def initialize(params = {})
    @search_params = immutable_copy(params[:search_params] || {})
    super
  end

  private

  def immutable_copy(value)
    case value
    when Hash
      value.each_with_object({}) do |(key, nested_value), copy|
        copy[immutable_copy(key)] = immutable_copy(nested_value)
      end.freeze
    when Array
      value.map { |nested_value| immutable_copy(nested_value) }.freeze
    when String
      value.dup.freeze
    else
      value
    end
  end

  def fetch_response(params)
    Uploadcare::Result.unwrap(
      api_client.search(params: search_params, query: params, request_options: request_options)
    )
  end

  def continuation_options
    { search_params: search_params }
  end
end
