require 'time'

module Uploadcare
  class Api::File < OpenStruct
    def initialize(api, *args)
      @api = api
      super(*args)
    end

    def delete
      @api.delete_file(uuid)
      reload
    end

    def store
      @api.store_file(uuid)
      reload
    end

    def cdn_url(*operations)
      operations = @table[:operations] + operations if @table[:operations]
      @api.cdn_url(uuid, *operations)
    end
    alias_method :public_url, :cdn_url

    def reload
      @table.update @api.file(uuid).instance_variable_get('@table')
    end

    def is_stored
      !!@table[:datetime_stored]
    end
    alias_method :is_public, :is_stored

    def uuid
      @table[:uuid]
    end
    alias_method :file_id, :uuid

    def datetime_stored
      Time.parse(@table[:datetime_stored]) if @table[:datetime_stored]
    end
    alias_method :last_keep_claim, :datetime_stored 

    def datetime_uploaded
      Time.parse(@table[:datetime_uploaded]) if @table[:datetime_uploaded]
    end
    alias_method :upload_date, :datetime_uploaded

    def datetime_removed
      Time.parse(@table[:datetime_removed]) if @table[:datetime_removed]
    end
    alias_method :removed, :datetime_removed
  end
end
