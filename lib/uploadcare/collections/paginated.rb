# frozen_string_literal: true

require 'uri'

# Paginated collection for API list responses.
#
# Wraps paginated API responses and provides methods for navigating between pages.
# Implements Enumerable for easy iteration over resources.
#
# @example Iterating over resources
#   files = client.files.list
#   files.each { |file| puts file.uuid }
#
# @example Navigating pages
#   files = client.files.list
#   while files
#     files.each { |file| process(file) }
#     files = files.next_page
#   end
#
# @example Fetching all resources
#   all_files = client.files.list.all
class Uploadcare::Collections::Paginated
  include Enumerable

  # @return [Array] Array of resource objects in the current page
  attr_reader :resources

  # @return [String, nil] URL for the next page, or nil if on last page
  attr_reader :next_page_url

  # @return [String, nil] URL for the previous page, or nil if on first page
  attr_reader :previous_page_url

  # @return [Integer] Number of items per page
  attr_reader :per_page

  # @return [Integer] Total number of items across all pages
  attr_reader :total

  # @return [Object] API endpoint client for fetching additional pages
  attr_reader :api_client

  # @return [Class] Resource class for instantiating items from raw data
  attr_reader :resource_class

  # @return [Uploadcare::Client, nil] Client for resource instantiation
  attr_reader :client

  # @return [Hash] Request options used when fetching pages
  attr_reader :request_options

  # Initialize a new Paginated collection.
  #
  # @param params [Hash] Collection parameters
  # @option params [Array] :resources Array of resource objects
  # @option params [String, nil] :next_page URL for next page
  # @option params [String, nil] :previous_page URL for previous page
  # @option params [Integer] :per_page Items per page
  # @option params [Integer] :total Total item count
  # @option params [Object] :api_client API client for fetching pages
  # @option params [Class] :resource_class Class for instantiating resources
  # @option params [Uploadcare::Client, nil] :client Client for resources
  # @option params [Hash] :request_options Request options for subsequent page fetches
  def initialize(params = {})
    @resources = params[:resources] || []
    @next_page_url = params[:next_page]
    @previous_page_url = params[:previous_page]
    @per_page = params[:per_page]
    @total = params[:total]
    @api_client = params[:api_client]
    @resource_class = params[:resource_class]
    @client = params[:client]
    @request_options = params[:request_options] || {}
  end

  # Iterate over resources in the current page.
  #
  # @yield [resource] Block to execute for each resource
  # @yieldparam resource [Object] A resource object
  def each(&)
    @resources.each(&)
  end

  # Fetch the next page of resources.
  #
  # @return [Uploadcare::Collections::Paginated, nil] Next page, or nil if on last page
  def next_page
    fetch_page(@next_page_url)
  end

  # Fetch the previous page of resources.
  #
  # @return [Uploadcare::Collections::Paginated, nil] Previous page, or nil if on first page
  def previous_page
    fetch_page(@previous_page_url)
  end

  # Fetch all resources across all pages.
  #
  # @return [Array<Object>] All resources
  def all
    collection = self
    items = []

    while collection
      items.concat(collection.resources || [])
      collection = collection.next_page
    end

    items
  end

  private

  def fetch_page(page_url)
    return nil unless page_url

    params = extract_params_from_url(page_url)
    response = fetch_response(params)
    build_paginated_collection(response)
  end

  def extract_params_from_url(page_url)
    uri = URI.parse(page_url)
    URI.decode_www_form(uri.query.to_s).to_h
  end

  def fetch_response(params)
    Uploadcare::Result.unwrap(api_client.list(params: params, request_options: request_options))
  end

  def build_paginated_collection(response)
    new_resources = build_resources(response['results'])

    self.class.new(
      resources: new_resources,
      next_page: response['next'],
      previous_page: response['previous'],
      per_page: response['per_page'],
      total: response['total'],
      api_client: api_client,
      resource_class: resource_class,
      client: client,
      request_options: request_options
    )
  end

  def build_resources(results)
    results.map { |data| resource_class.new(data, client) }
  end
end
