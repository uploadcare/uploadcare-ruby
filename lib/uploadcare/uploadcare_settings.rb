module Uploadcare
  PUBLIC_KEY = ENV.fetch('UPLOADCARE_PUBLIC_KEY') || 'demopublickey'
  SECRET_KEY = ENV.fetch('UPLOADCARE_SECRET_KEY') || 'demoprivatekey'
  AUTH_TYPE = 'Uploadcare.Simple'
end
