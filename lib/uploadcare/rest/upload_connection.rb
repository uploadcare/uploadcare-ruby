require "faraday"

module Uploadcare
  module Connections
    class UploadConnection < Faraday::Connection
      def initialize options
        ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs')

        super ssl: { ca_path: ca_path }, url: options[:upload_url_base] do |frd|
          frd.request :multipart
          frd.request :url_encoded
          frd.adapter Faraday.default_adapter
          frd.headers['User-Agent'] = Uploadcare::user_agent
        end
      end
    end
  end
end