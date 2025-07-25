# frozen_string_literal: true

module Uploadcare
  module SignedUrlGenerators
    class BaseGenerator
      attr_reader :cdn_host, :secret_key

      def initialize(cdn_host:, secret_key:)
        @cdn_host = cdn_host
        @secret_key = secret_key
      end

      def generate_url(_uuid, _expiration = nil)
        raise NotImplementedError, 'Subclasses must implement generate_url method'
      end

      private

      def build_url(path, query_params = {})
        uri = URI("https://#{cdn_host}#{path}")
        uri.query = URI.encode_www_form(query_params) unless query_params.empty?
        uri.to_s
      end
    end
  end
end
