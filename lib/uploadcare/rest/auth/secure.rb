module Uploadcare
  module Connections
    module Auth
      class Secure < Base

        def apply(env)
          date = Time.now.utc
          headers(env, date).each{|k, v| env.request_headers[k] = v}
          env
        end

        private

        def headers(env, date)
          {
            "Date" => date.rfc2822,
            "Authorization" => "Uploadcare #{public_key}:#{signature(env, date)}"
          }
        end

        def signature(env, date)
          sign_string = sign_string(env, date)
          digest = OpenSSL::Digest.new('sha1')

          OpenSSL::HMAC.hexdigest(digest, private_key, sign_string)
        end

        def sign_string(env, date)
          verb = env.method.upcase.to_s
          uri = env.url.request_uri
          date_header = date.rfc2822
          content_type = env.request_headers['Content-Type']
          content_md5 = OpenSSL::Digest.new('md5').hexdigest(env.body || "")

          [verb, content_md5, content_type, date_header, uri].join("\n")
        end

      end
    end
  end
end
