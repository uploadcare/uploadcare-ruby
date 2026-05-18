# frozen_string_literal: true

require 'rubygems'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('<uploadcare_public_key>') do
    ENV.fetch('UPLOADCARE_PUBLIC_KEY', Uploadcare.configuration.public_key)
  end
  config.filter_sensitive_data('<uploadcare_secret_key>') do
    ENV.fetch('UPLOADCARE_SECRET_KEY', Uploadcare.configuration.secret_key)
  end
  config.filter_sensitive_data('<uploadcare_public_key>') { 'demopublickey' }
  config.filter_sensitive_data('<uploadcare_secret_key>') { 'demosecretkey' }
  config.before_record do |i|
    if i.request.body && i.request.body.size > 1024 * 1024
      i.request.body = "Big string (#{i.request.body.size / (1024 * 1024)}) MB"
    end

    if (auth = i.request.headers['Authorization']&.first)
      auth = auth.gsub(/\AUploadcare\.Simple\s+[^:\s]+:[^\s]+\z/,
                       'Uploadcare.Simple <uploadcare_authorization>')
      auth = auth.gsub(/\AUploadcare\s+[^:\s]+:[^\s]+\z/, 'Uploadcare <uploadcare_authorization>')
      i.request.headers['Authorization'] = [auth]
    end

    i.request.uri = i.request.uri.gsub(/([?&]token=)[^&]+/, '\1<uploadcare_upload_token>') if i.request.uri

    if i.request.body
      i.request.body = i.request.body.gsub(/("token"\s*:\s*")[^"]+("\s*(?:\x7D|\x5D))/,
                                           '\1<uploadcare_upload_token>\2')
      i.request.body = i.request.body.gsub(/(name="signature"\r\n\r\n)[^\r\n]+/, '\1<uploadcare_signature>')
      i.request.body = i.request.body.gsub(/(name="expire"\r\n\r\n)[^\r\n]+/, '\1<uploadcare_expire>')
    end

    if i.response.body.is_a?(String)
      i.response.body = i.response.body.gsub(/("token"\s*:\s*")[^"]+("\s*(?:\x7D|\x5D))/,
                                             '\1<uploadcare_upload_token>\2')
    end
  end
  config.configure_rspec_metadata!
end
