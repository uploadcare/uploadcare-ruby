# frozen_string_literal: true

Gem.find_files('client/**/*.rb').each { |path| require path }
Gem.find_files('entity/**/*.rb').each { |path| require path }

module Uploadcare
  # End-user interface
  class Api
    extend Forwardable
    include Entity

    def_delegator File, :file
    def_delegators FileList, :file_list, :store_files, :delete_files
    # def_delegators Group, :group
    def_delegators Project, :project
    def_delegators Uploader, :upload, :upload_files, :upload_url
  end
end
