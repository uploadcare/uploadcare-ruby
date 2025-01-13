# frozen_string_literal: true

require 'uri'

module Uploadcare
  class PaginatedCollection
    include Enumerable
    attr_reader :resources, :next_page_url, :previous_page_url, :per_page, :total, :client, :resource_class

    def initialize(params = {})
      @resources = params[:resources]
      @next_page_url = params[:next_page]
      @previous_page_url = params[:previous_page]
      @per_page = params[:per_page]
      @total = params[:total]
      @client = params[:client]
      @resource_class = params[:resource_class]
    end

    def each(&block)
      @resources.each(&block)
    end

    # Fetches the next page of resources
    # Returns [nil] if next_page_url is nil
    # @return [Uploadcare::FileList]
    def next_page
      fetch_page(@next_page_url)
    end

    # Fetches the previous page of resources
    # Returns [nil] if previous_page_url is nil
    # @return [Uploadcare::FileList]
    def previous_page
      fetch_page(@previous_page_url)
    end

    # TODO: Add #all method which return an array of resource

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
