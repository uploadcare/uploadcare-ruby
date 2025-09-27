# frozen_string_literal: true

module Uploadcare
  module Concerns
    # Adds caching capabilities to resources
    module Cacheable
      extend ActiveSupport::Concern if defined?(ActiveSupport)

      included do
        class_attribute :cache_store
        class_attribute :cache_expires_in, default: 300 # 5 minutes default
      end

      class_methods do
        def cached_find(uuid, expires_in: nil)
          return find(uuid) unless cache_enabled?

          cache_key = "uploadcare:#{name.underscore}:#{uuid}"
          expires = expires_in || cache_expires_in

          cache_store.fetch(cache_key, expires_in: expires) do
            find(uuid)
          end
        end

        def cache_enabled?
          cache_store.present?
        end

        def clear_cache(uuid = nil)
          if uuid
            cache_key = "uploadcare:#{name.underscore}:#{uuid}"
            cache_store.delete(cache_key)
          else
            # Clear all cache for this resource type
            cache_store.clear if cache_store.respond_to?(:clear)
          end
        end
      end

      def cache_key
        "uploadcare:#{self.class.name.underscore}:#{uuid || id}"
      end

      def expire_cache
        self.class.cache_store&.delete(cache_key)
      end

      def cached_info(expires_in: nil)
        return info unless self.class.cache_enabled?

        expires = expires_in || self.class.cache_expires_in
        self.class.cache_store.fetch("#{cache_key}:info", expires_in: expires) do
          info
        end
      end
    end
  end
end