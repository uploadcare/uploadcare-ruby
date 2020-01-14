# This object returns headers needed for authentication
# Simple header is relatively unsafe, but can be useful for debug
# uploadcare headers are safer; therefore they are default

module Uploadcare
  class AuthenticationHeader
    def self.call
      if AUTH_TYPE == 'Uploadcare'
        self.call_secure
      else
        self.call_simple
      end
    end

    def self.call_simple
      { 'Authorization': "Uploadcare.Simple #{PUBLIC_KEY}:#{SECRET_KEY}" }
    end

    def self.call_secure
      raise('Not implemented yet')
    end

    def timestamp
      Time.now.gmtime.strftime('%a, %d %b %Y %H:%M:%S GMT')
    end
  end
end
