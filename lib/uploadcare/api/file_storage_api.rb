module Uploadcare
  module FileStorageApi
    MAX_BATCH_SIZE = 100
    UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

    def store_files(objects)
      if objects.size > MAX_BATCH_SIZE
        raise ArgumentError, "Up to #{MAX_BATCH_SIZE} files are supported per request, #{objects.size} given"
      end

      put "/files/storage/", to_uuids(objects)
    end

    def delete_files(objects)
      if objects.size > MAX_BATCH_SIZE
        raise ArgumentError, "Up to #{MAX_BATCH_SIZE} files are supported per request, #{objects.size} given"
      end

      delete "/files/storage/", to_uuids(objects)
    end

    private

    def to_uuids(objects)
      objects.map do |object|
        case object
        when Uploadcare::Api::File then object.uuid
        when UUID_REGEX then object
        else raise(ArgumentError, "Unable to convert object to uuid: #{object}")
        end
      end
    end
  end
end
