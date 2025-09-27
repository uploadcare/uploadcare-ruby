# frozen_string_literal: true

module Uploadcare
  module Rails
    # ActiveRecord integration for Uploadcare files
    module ActiveRecord
      extend ActiveSupport::Concern

      class_methods do
        # Define an Uploadcare file attribute
        # @param attribute [Symbol] The attribute name
        # @param options [Hash] Options for the attribute
        # @option options [Boolean] :store (true) Whether to store files permanently
        # @option options [Hash] :validations Validation rules for the file
        def has_uploadcare_file(attribute, **options)
          store_option = options.fetch(:store, true)
          validations = options.fetch(:validations, {})

          # UUID attribute getter/setter
          define_method "#{attribute}_uuid" do
            read_attribute("#{attribute}_uuid")
          end

          define_method "#{attribute}_uuid=" do |value|
            write_attribute("#{attribute}_uuid", value)
            @uploadcare_files ||= {}
            @uploadcare_files[attribute] = nil # Clear cached file
          end

          # File object getter
          define_method attribute do
            uuid = send("#{attribute}_uuid")
            return nil unless uuid.present?

            @uploadcare_files ||= {}
            @uploadcare_files[attribute] ||= begin
              file = Uploadcare::File.new(uuid: uuid)
              file.store if store_option && !file.stored?
              file
            end
          end

          # File object setter
          define_method "#{attribute}=" do |value|
            @uploadcare_files ||= {}

            case value
            when Uploadcare::File
              send("#{attribute}_uuid=", value.uuid)
              @uploadcare_files[attribute] = value
            when String
              # Assume it's a UUID
              send("#{attribute}_uuid=", value)
            when Hash
              # Upload from hash (e.g., from form)
              if value[:file].present?
                uploaded = Uploadcare::Uploader.upload(value[:file], store: store_option)
                send("#{attribute}_uuid=", uploaded.uuid)
                @uploadcare_files[attribute] = uploaded
              end
            when nil
              send("#{attribute}_uuid=", nil)
              @uploadcare_files[attribute] = nil
            else
              # Try to upload the object
              uploaded = Uploadcare::Uploader.upload(value, store: store_option)
              send("#{attribute}_uuid=", uploaded.uuid)
              @uploadcare_files[attribute] = uploaded
            end
          end

          # URL helper
          define_method "#{attribute}_url" do |transformations = nil|
            file = send(attribute)
            return nil unless file

            if transformations
              file.build_url_with_transformations(transformations)
            else
              file.original_file_url
            end
          end

          # Add validations if specified
          if validations.any?
            validate do
              file = send(attribute)
              next unless file

              if validations[:size] && file.size > validations[:size]
                errors.add(attribute, "file size exceeds #{validations[:size]} bytes")
              end

              if validations[:mime_types] && !validations[:mime_types].include?(file.mime_type)
                errors.add(attribute, "invalid file type")
              end
            end
          end
        end

        # Define multiple Uploadcare files (group)
        def has_uploadcare_files(attribute, **options)
          store_option = options.fetch(:store, true)

          # Group UUID getter/setter
          define_method "#{attribute}_group_uuid" do
            read_attribute("#{attribute}_group_uuid")
          end

          define_method "#{attribute}_group_uuid=" do |value|
            write_attribute("#{attribute}_group_uuid", value)
            @uploadcare_groups ||= {}
            @uploadcare_groups[attribute] = nil
          end

          # Group getter
          define_method attribute do
            group_uuid = send("#{attribute}_group_uuid")
            return [] unless group_uuid.present?

            @uploadcare_groups ||= {}
            @uploadcare_groups[attribute] ||= begin
              group = Uploadcare::Group.new(uuid: group_uuid)
              group.store if store_option
              group.files
            end
          end

          # Group setter
          define_method "#{attribute}=" do |values|
            @uploadcare_groups ||= {}

            case values
            when Array
              # Array of files or UUIDs
              uuids = values.map do |v|
                case v
                when Uploadcare::File then v.uuid
                when String then v
                else
                  uploaded = Uploadcare::Uploader.upload(v, store: store_option)
                  uploaded.uuid
                end
              end

              group = Uploadcare::Group.create(uuids)
              send("#{attribute}_group_uuid=", group.id)
              @uploadcare_groups[attribute] = group.files
            when Uploadcare::Group
              send("#{attribute}_group_uuid=", values.id)
              @uploadcare_groups[attribute] = values.files
            when nil
              send("#{attribute}_group_uuid=", nil)
              @uploadcare_groups[attribute] = nil
            end
          end
        end
      end

      # Instance methods
      def uploadcare_files
        @uploadcare_files ||= {}
      end

      def uploadcare_groups
        @uploadcare_groups ||= {}
      end

      def clear_uploadcare_cache
        @uploadcare_files = {}
        @uploadcare_groups = {}
      end
    end
  end
end