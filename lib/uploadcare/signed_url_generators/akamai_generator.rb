# frozen_string_literal: true

require_relative 'base_generator'

module Uploadcare
  module SignedUrlGenerators
    class AkamaiGenerator < Uploadcare::SignedUrlGenerators::BaseGenerator
      UUID_REGEX = '[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}'
      TEMPLATE = 'https://{cdn_host}/{uuid}/?token=exp={expiration}{delimiter}acl={acl}{delimiter}hmac={token}'

      def generate_url(uuid, acl = uuid, wildcard: false)
        raise ArgumentError, 'Must contain valid UUID' unless valid?(uuid)

        formated_acl = build_acl(uuid, acl, wildcard: wildcard)
        expire = build_expire
        signature = build_signature(expire, formated_acl)

        TEMPLATE.gsub('{delimiter}', delimiter)
                .sub('{cdn_host}', sanitized_string(cdn_host))
                .sub('{uuid}', sanitized_string(uuid))
                .sub('{acl}', formated_acl)
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
          "/#{sanitized_string(uuid)}/*"
        else
          "/#{sanitized_string(acl)}/"
        end
      end

      def build_expire
        (Time.now.to_i + ttl).to_s
      end

      def build_signature(expire, acl)
        signature = %W[exp=#{expire} acl=#{acl}].join(delimiter)
        OpenSSL::HMAC.hexdigest(algorithm, secret_key, signature)
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
