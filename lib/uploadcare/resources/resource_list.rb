require 'ostruct'

module Uploadcare
  class Api
    class ResourceList
      include Enumerable

      extend Forwardable
      def_delegator :@data, :meta
      def_delegator :@data, :objects
      def_delegator :objects, :[]

      attr_reader :options

      def initialize(api, data, options)
        @api = api
        @data = OpenStruct.new(
          meta: data.reject{|k, _| k == 'results'}.freeze,
          objects: data['results'].map{|object| to_resource(api, object)}
        )
        @options = options.dup.freeze
      end

      def each
        return enum_for(:each) unless block_given?

        objects.each{|object| yield object}

        unless fully_loaded?
          next_page = get_next_page
          next_page.each(&Proc.new)
        end

        self
      ensure
        @data = OpenStruct.new(
          meta: next_page.meta,
          objects: objects + next_page.objects
        ) if next_page
      end

      # TODO: #delete and #store methods

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

      def get_next_page
        return nil if fully_loaded?

        next_page_data = api.get(@data.meta['next'])
        next_page = self.class.new(api, next_page_data, options)
      end

      def to_resource(*args)
        raise NotImplementedError, 'You must define this method in a child class'
      end
    end
  end
end
