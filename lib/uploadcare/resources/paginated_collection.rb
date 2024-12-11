# frozen_string_literal: true

require 'uri'

module Uploadcare
  class PaginatedCollection
    include Enumerable

    attr_reader :resources, :next_page_url, :previous_page_url, :per_page, :total, :client, :resource_class

    def initialize(resources:, next_page:, previous_page:, per_page:, total:, client:, resource_class:)
      @resources = resources
      @next_page_url = next_page
      @previous_page_url = previous_page
      @per_page = per_page
      @total = total
      @client = client
      @resource_class = resource_class
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

      uri = URI.parse(page_url)
      params = URI.decode_www_form(uri.query.to_s).to_h
      response = client.list(params)
      new_resources = response['results'].map { |resource_data| resource_class.new(resource_data, client.config) }

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
  end
end
