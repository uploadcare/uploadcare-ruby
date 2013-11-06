module Uploadcare
  class Api
    class Project < OpenStruct
      # unfortunatly there is not way to use alias method
      # openstruct methods are defined AFTER the initialization hook, so - 
      # just ugly proxy patch
      def public_key
        @table[:pub_key] if @table[:pub_key]
      end

      def initialize api, project
        @api = api
        super(
          name: project["name"],
          pub_key: project["pub_key"],
          collaborators: project["collaborators"].map {|c| Collaborator.new(c)},
          autostore_enabled: project["autostore_enabled"]
        )
      end

      class Collaborator < OpenStruct
      end
    end
  end
end
