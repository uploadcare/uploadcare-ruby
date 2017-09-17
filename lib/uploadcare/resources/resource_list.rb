require 'ostruct'

module Uploadcare
  class Api
    class ResourceList
      include Enumerable

      extend Forwardable
      def_delegator :@data, :meta
      def_delegator :@data, :objects

      attr_reader :options

      def initialize(api, data, options)
        @api = api
        @data = build_data(data)
        @options = options.dup.freeze
      end

      def [](index)
        first(index + 1).last
      end

      def each
        return enum_for(:each) unless block_given?

        resource_enumerator.each { |object| yield object }

        self
      end

      def total
        meta['total']
      end

      def loaded
        objects.size
      end

      def fully_loaded?
        meta['next'].nil?
      end

      private

      attr_reader :api

      def build_data(data_hash)
        OpenStruct.new(
          meta: data_hash.reject{|k, _| k == 'results'}.freeze,
          objects: data_hash['results'].map{|object| to_resource(api, object)}
        )
      end

      def get_next_page
        return nil if fully_loaded?

        next_page = build_data(api.get(@data.meta['next']))

        @data = OpenStruct.new(
          meta: next_page.meta,
          objects: objects + next_page.objects
        )

        next_page
      end

      def to_resource(*args)
        raise NotImplementedError, 'You must define this method in a child class'
      end

      def resource_enumerator
        Enumerator.new do |yielder|
          objects.each { |obj| yielder << obj }

          while next_page = get_next_page do
            next_page.objects.each { |obj| yielder << obj }
          end
        end
      end
    end
  end
end
