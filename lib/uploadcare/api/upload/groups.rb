# frozen_string_literal: true

# Upload API endpoint for group operations.
#
# @see https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup
module Uploadcare
  module Api
    class Upload
      class Groups
        # @return [Uploadcare::Api::Upload] Parent Upload client
        attr_reader :upload

        # @param upload [Uploadcare::Api::Upload] Parent Upload client
        def initialize(upload:)
          @upload = upload
        end

        # Create a file group from UUIDs (POST /group/).
        #
        # @param files [Array<String>] Array of file UUIDs or objects responding to #uuid
        # @param options [Hash] Group creation options (:signature, :expire)
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Group information
        # @raise [ArgumentError] if files is empty or not an array
        # @see https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup
        def create(files:, request_options: {}, **options)
          Uploadcare::Result.capture do
            raise ArgumentError, 'files must be an array' unless files.is_a?(Array)
            raise ArgumentError, 'files cannot be empty' if files.empty?

            params = build_group_params(files, options)
            Uploadcare::Result.unwrap(
              upload.post(path: 'group/', params: params, headers: {}, request_options: request_options)
            )
          end
        end

        # Get group info (GET /group/info/).
        #
        # @param group_id [String] Group UUID
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Group information
        # @raise [ArgumentError] if group_id is empty
        # @see https://uploadcare.com/api-refs/upload-api/#operation/filesGroupInfo
        def info(group_id:, request_options: {})
          Uploadcare::Result.capture do
            raise ArgumentError, 'group_id cannot be empty' if group_id.to_s.strip.empty?

            Uploadcare::Result.unwrap(
              upload.get(path: 'group/info/',
                         params: { pub_key: upload.config.public_key, group_id: group_id },
                         request_options: request_options)
            )
          end
        end

        private

        def build_group_params(files, options)
          params = { 'pub_key' => upload.config.public_key }

          files.each_with_index do |file, index|
            uuid = file.respond_to?(:uuid) ? file.uuid : file.to_s
            params["files[#{index}]"] = uuid
          end

          params['signature'] = (options[:signature] || options['signature']).to_s if options[:signature] || options['signature']
          params['expire'] = (options[:expire] || options['expire']).to_s if options[:expire] || options['expire']

          params
        end
      end
    end
  end
end
