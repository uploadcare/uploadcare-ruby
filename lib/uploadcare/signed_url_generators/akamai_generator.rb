# frozen_string_literal: true

require_relative 'base_generator'

module Uploadcare
  module SignedUrlGenerators
    class AkamaiGenerator < Uploadcare::SignedUrlGenerators::BaseGenerator
      UUID_REGEX = '[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}'
      TEMPLATE = 'https://{cdn_host}/{uuid}/?token=exp={expiration}{delimiter}acl={acl}{delimiter}hmac={token}'

      def generate_url(uuid, acl = uuid, wildcard: false)
        raise ArgumentError, 'Must contain valid UUID' unless valid?(uuid)

        formatted_acl = build_acl(uuid, acl, wildcard: wildcard)
        expire = build_expire
        signature = build_signature(expire, formatted_acl)

        TEMPLATE.gsub('{delimiter}', delimiter)
                .sub('{cdn_host}', sanitized_string(cdn_host))
                .sub('{uuid}', sanitized_string(uuid))
                .sub('{acl}', formatted_acl)
                .sub('{expiration}', expire)
                .sub('{token}', signature)
      end

      private

      def valid?(uuid)
        uuid.match(UUID_REGEX)
      end

      def delimiter
        '~'
      end

      def build_acl(uuid, acl, wildcard: false)
        if wildcard
          "/#{sanitized_delimiter_path(uuid)}/*"
        else
          "/#{sanitized_delimiter_path(acl)}/"
        end
      end

      # Delimiter sanitization referenced from: https://github.com/uploadcare/pyuploadcare/blob/main/pyuploadcare/secure_url.py#L74
      def sanitized_delimiter_path(path)
        sanitized_string(path).gsub('~') { |escape_char| "%#{escape_char.ord.to_s(16).downcase}" }
      end

      def build_expire
        (Time.now.to_i + ttl).to_s
      end

      def build_signature(expire, acl)
        signature = ["exp=#{expire}", "acl=#{acl}"].join(delimiter)
        secret_key_bin = Array(secret_key.gsub(/\s/, '')).pack('H*')
        OpenSSL::HMAC.hexdigest(algorithm, secret_key_bin, signature)
      end

      # rubocop:disable Style/SlicingWithRange
      def sanitized_string(string)
        string = string[1..-1] if string[0] == '/'
        string = string[0...-1] if string[-1] == '/'
        string.strip
      end
      # rubocop:enable Style/SlicingWithRange
    end
  end
end
