# frozen_string_literal: true

module Uploadcare
  # Rails-style query interface for Uploadcare resources
  class Query
    include Enumerable

    attr_reader :resource_class, :params

    def initialize(resource_class, params = {})
      @resource_class = resource_class
      @params = params
      @executed = false
      @results = nil
    end

    # Chainable query methods
    def where(conditions)
      chain(conditions)
    end

    def limit(value)
      chain(limit: value)
    end

    def offset(value)
      chain(from: value)
    end

    def order(field, direction = :asc)
      ordering = direction == :desc ? "-#{field}" : field.to_s
      chain(ordering: ordering)
    end

    def stored(value = true)
      chain(stored: value)
    end

    def removed(value = false)
      chain(removed: value)
    end

    # Execution methods
    def to_a
      execute unless executed?
      @results
    end

    def each(&block)
      to_a.each(&block)
    end

    def first(n = nil)
      if n
        limit(n).to_a
      else
        limit(1).to_a.first
      end
    end

    def last(n = nil)
      if n
        order(:datetime_uploaded, :desc).limit(n).to_a
      else
        order(:datetime_uploaded, :desc).limit(1).to_a.first
      end
    end

    def count
      execute unless executed?
      @total_count || @results.size
    end

    def exists?
      !first.nil?
    end

    def empty?
      count == 0
    end

    def any?(&block)
      if block_given?
        to_a.any?(&block)
      else
        !empty?
      end
    end

    def all?(&block)
      to_a.all?(&block)
    end

    # Batch operations
    def find_each(batch_size: 100)
      return enum_for(:find_each, batch_size: batch_size) unless block_given?

      offset_value = nil
      loop do
        batch_query = offset_value ? offset(offset_value).limit(batch_size) : limit(batch_size)
        batch = batch_query.to_a
        
        break if batch.empty?
        
        batch.each { |item| yield item }
        
        break if batch.size < batch_size
        offset_value = batch.last.uuid
      end
    end

    def find_in_batches(batch_size: 100)
      return enum_for(:find_in_batches, batch_size: batch_size) unless block_given?

      find_each(batch_size: batch_size).each_slice(batch_size) do |batch|
        yield batch
      end
    end

    # Pagination
    def page(number, per_page: 20)
      offset_value = (number - 1) * per_page
      limit(per_page).offset(offset_value)
    end

    def next_page
      return nil unless @next_url
      self.class.new(resource_class, extract_params_from_url(@next_url))
    end

    def previous_page
      return nil unless @previous_url
      self.class.new(resource_class, extract_params_from_url(@previous_url))
    end

    # Pluck specific attributes
    def pluck(*attributes)
      to_a.map do |item|
        if attributes.size == 1
          item.send(attributes.first)
        else
          attributes.map { |attr| item.send(attr) }
        end
      end
    end

    def ids
      pluck(:uuid)
    end

    # Cache control
    def cached(expires_in: 5.minutes)
      @cache_expires_in = expires_in
      self
    end

    def fresh
      @cache_expires_in = 0
      self
    end

    private

    def chain(new_params)
      self.class.new(resource_class, params.merge(new_params))
    end

    def execute
      @executed = true
      
      if resource_class.respond_to?(:list)
        result = resource_class.list(params)
        
        if result.respond_to?(:results)
          @results = result.results
          @total_count = result.total
          @next_url = result.next
          @previous_url = result.previous
        else
          @results = Array(result)
        end
      else
        @results = []
      end
    end

    def executed?
      @executed
    end

    def extract_params_from_url(url)
      # Extract query parameters from URL
      uri = URI.parse(url)
      Rack::Utils.parse_nested_query(uri.query)
    end
  end

  # Module to add query interface to resources
  module Queryable
    extend ActiveSupport::Concern if defined?(ActiveSupport)

    class_methods do
      def where(conditions)
        Query.new(self, conditions)
      end

      def limit(value)
        Query.new(self).limit(value)
      end

      def order(field, direction = :asc)
        Query.new(self).order(field, direction)
      end

      def stored(value = true)
        Query.new(self).stored(value)
      end

      def removed(value = false)
        Query.new(self).removed(value)
      end

      def all
        Query.new(self)
      end

      def first(n = nil)
        Query.new(self).first(n)
      end

      def last(n = nil)
        Query.new(self).last(n)
      end

      def find_each(**options, &block)
        Query.new(self).find_each(**options, &block)
      end

      def find_in_batches(**options, &block)
        Query.new(self).find_in_batches(**options, &block)
      end

      def exists?(**conditions)
        where(conditions).exists?
      end

      def count
        Query.new(self).count
      end

      def pluck(*attributes)
        Query.new(self).pluck(*attributes)
      end
    end
  end
end