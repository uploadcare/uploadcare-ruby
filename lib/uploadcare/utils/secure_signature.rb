module Uploadcare
  # Generates signatures in the format required for signed uploads

  class SecureSignature
    def initialize(api_secret_key, expire)
      @secret = api_secret_key
      @expire = expire
    end

    def generate
      time = (Time.now + @expire).to_i
      {
        signature: nil,
        expire: time,
      }
    end
  end
end