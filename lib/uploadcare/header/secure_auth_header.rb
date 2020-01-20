# This object returns headers needed for authentication
# This authentication method is more secure, but more tedious
# https://uploadcare.com/docs/api_reference/rest/requests_auth/#auth-uploadcare

require 'digest/md5'

module Uploadcare
  class SecureAuthHeader
    def self.call(method: 'GET', content: '', content_type: 'application/json', uri: '')
      @method = method
      @content = content
      @content_type = content_type
      @uri = uri
      @date_for_header = self.timestamp
      {
        'Date': @date_for_header,
        'Authorization': "Uploadcare #{PUBLIC_KEY}:#{self.signature}"
      }
    end

    protected

    def self.signature
      content_md5 = Digest::MD5.hexdigest(@content)
      sign_string = [@method, content_md5, @content_type, @date_for_header, @uri].join("\n")
      digest = OpenSSL::Digest.new('sha1')
      OpenSSL::HMAC.hexdigest(digest, SECRET_KEY, sign_string)
    end

    def self.timestamp
      Time.now.gmtime.strftime('%a, %d %b %Y %H:%M:%S GMT')
    end
  end
end
