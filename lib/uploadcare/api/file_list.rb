module Uploadcare  
  class Api::FileList
    attr_accessor :files, :page, :per_page, :total, :pages
    
    def initialize api, response
      @api = api
      @files = response['results'].map{ |obj| Api::File.new(api, obj) }
      @page = response['page'].to_i
      @per_page = response['per_page'].to_i
      @total = response['total'].to_i
      @pages = response['pages'].to_i
    end

    # we need to get rid of @api.files.files[]
    # for now on we will proxy the [] method down to the actual files collection.
    def [] index
      @files[index]
    end

    #we already have files array, now we just have to return it back to user. 
    def to_a
      @files
    end
  end
end
