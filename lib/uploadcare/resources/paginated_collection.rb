# frozen_string_literal: true

require 'uri'

module Uploadcare
  # Paginated collection for API list responses
  #
  # Wraps paginated API responses and provides methods for navigating between pages.
  # Implements Enumerable for easy iteration over resources.
  #
  # @example Iterating over resources
  #   files = Uploadcare::File.list
  #   files.each { |file| puts file.uuid }
  #
  # @example Navigating pages
  #   files = Uploadcare::File.list
  #   while files
  #     files.each { |file| process(file) }
  #     files = files.next_page
  #   end
  #
  # @see Uploadcare::File.list
  # @see Uploadcare::Group.list
  class PaginatedCollection
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

    # @return [Object] Client instance for fetching additional pages
    attr_reader :client

    # @return [Class] Resource class for instantiating items
    attr_reader :resource_class

    # Initialize a new PaginatedCollection
    #
    # @param params [Hash] Collection parameters
    # @option params [Array] :resources Array of resource objects
    # @option params [String, nil] :next_page URL for next page
    # @option params [String, nil] :previous_page URL for previous page
    # @option params [Integer] :per_page Items per page
    # @option params [Integer] :total Total item count
    # @option params [Object] :client Client for fetching pages
    # @option params [Class] :resource_class Class for instantiating resources
    # @return [Uploadcare::PaginatedCollection] new collection instance
    def initialize(params = {})
      @resources = params[:resources]
      @next_page_url = params[:next_page]
      @previous_page_url = params[:previous_page]
      @per_page = params[:per_page]
      @total = params[:total]
      @client = params[:client]
      @resource_class = params[:resource_class]
    end

    # Iterate over resources in the current page
    #
    # @yield [resource] Block to execute for each resource
    # @yieldparam resource [Object] A resource object
    def each(&)
      @resources.each(&)
    end

    # Fetch the next page of resources
    #
    # @return [Uploadcare::PaginatedCollection, nil] Next page collection, or nil if on last page
    def next_page
      fetch_page(@next_page_url)
    end

    # Fetch the previous page of resources
    #
    # @return [Uploadcare::PaginatedCollection, nil] Previous page collection, or nil if on first page
    def previous_page
      fetch_page(@previous_page_url)
    end

    # TODO: Add #all method which return an array of resource

    private

    # Fetch a specific page by URL
    # @param page_url [String, nil] URL of the page to fetch
    # @return [Uploadcare::PaginatedCollection, nil] Fetched page or nil
    # @api private
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
      client.list(params)
    end

    def build_paginated_collection(response)
      new_resources = build_resources(response['results'])

      self.class.new(
        resources: new_resources,
        next_page: response['next'],
        previous_page: response['previous'],
        per_page: response['per_page'],
        total: response['total'],
        client: client,
        resource_class: resource_class
      )
    end

    def build_resources(results)
      results.map { |resource_data| resource_class.new(resource_data, client.config) }
    end
  end
end
