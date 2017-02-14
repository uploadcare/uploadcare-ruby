module Uploadcare
  module FileStorageApi
    BATCH_SIZE = 100
    UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

    def store_files(objects)
      in_batches(objects) { |batch| put "/files/storage/", to_uuids(batch) }
    end

    def delete_files(objects)
      in_batches(objects) { |batch| delete "/files/storage/", to_uuids(batch) }
    end

    private

    def in_batches(enum)
      enum.each_slice(BATCH_SIZE) { |batch| yield batch }
    end

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
