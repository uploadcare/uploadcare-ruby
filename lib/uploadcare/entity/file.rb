# frozen_string_literal: true

module Uploadcare
  module Entity
    # This serializer returns a single file
    # https://uploadcare.com/docs/api_reference/rest/handling_projects/
    class File < ApiStruct::Entity
      client_service FileClient

      attr_entity :datetime_removed, :datetime_stored, :datetime_uploaded, :image_info, :is_image, :is_ready,
                  :mime_type, :original_file_url, :original_filename, :size, :url, :uuid
    end
  end
end
