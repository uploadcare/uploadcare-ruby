# frozen_string_literal: true

module Uploadcare
  module Entity
    # @abstract
    module Decorator
      # provides pagination methods for things in Uploadcare that paginate,
      # namely [FileList] and [Group]
      #
      # Requirements:
      # - Should be Entity with Client
      # - Associated Client should have `list` method that returns objects with pagination
      # - Response should have :next, :previous, :total, :per_page params and :results fields
      module Paginator
        @entity ||= Hashie::Mash.new

        # meta data of a pagination object
        def meta
          Hashie::Mash.new(next: @entity[:next], previous: @entity[:previous],
                           total: @entity[:total], per_page: @entity[:per_page])
        end

        # Returns new instance of current object on next page
        def next_page
          url = @entity[:next]
          return unless url

          query = URI.decode_www_form(URI(url).query).to_h.transform_keys(&:to_sym)
          self.class.list(**query)
        end

        # Returns new instance of current object on previous page
        def previous_page
          url = @entity[:previous]
          return unless url

          query = URI.decode_www_form(URI(url).query).to_h.transform_keys(&:to_sym)
          self.class.list(**query)
        end

        # Attempts to load the entire list after offset into results of current object
        #
        # It's possible to avoid loading objects on previous pages by offsetting them first
        def load
          return if @entity[:next].nil? || @entity[:results].length == @entity[:total]

          np = self
          until np.next.nil?
            np = np.next_page
            @entity[:results].concat(np.results.map(&:to_h))
          end
          @entity[:next] = nil
          @entity[:per_page] = @entity[:total]
          self
        end

        # iterate through pages, starting with current one
        #
        # @yield [Block]
        def each
          current_page = self
          while current_page
            current_page.results.each do |obj|
              yield obj
            end
            current_page = current_page.next_page
          end
        end

        # Load and return all objects in list
        #
        # @return [Array]
        def all
          load[:results]
        end
      end
    end
  end
end
