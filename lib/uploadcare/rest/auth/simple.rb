module Uploadcare
  module Connections
    module Auth
      class Simple < Base

        def apply(env)
          auth_string = "Uploadcare.Simple #{public_key}:#{private_key}"
          env.request_headers['Authorization'] = auth_string

          env
        end

      end
    end
  end
end
