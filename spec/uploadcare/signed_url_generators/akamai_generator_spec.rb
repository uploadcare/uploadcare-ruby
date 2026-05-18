# frozen_string_literal: true

require 'openssl'

RSpec.describe Uploadcare::SignedUrlGenerators::AkamaiGenerator do
  it 'generates signed url' do
    allow(Time).to receive(:now).and_return(Time.at(1000))
    uuid = 'e1fe0a80-0000-4000-8000-000000000000'
    secret_key = '0123456789abcdef'

    generator = described_class.new(cdn_host: 'cdn.test', secret_key: secret_key, ttl: 300, algorithm: 'sha256')

    signature_data = "exp=1300~acl=/#{uuid}/"
    secret_key_bin = Array(secret_key.delete(" \t\r\n")).pack('H*')
    expected_hmac = OpenSSL::HMAC.hexdigest('sha256', secret_key_bin, signature_data)
    expected = "https://cdn.test/#{uuid}/?token=exp=1300~acl=/#{uuid}/~hmac=#{expected_hmac}"

    expect(generator.generate_url(uuid)).to eq(expected)
  end

  it 'generates signed url with wildcard acl' do
    allow(Time).to receive(:now).and_return(Time.at(1000))
    uuid = 'e1fe0a80-0000-4000-8000-000000000000'
    secret_key = '0123456789abcdef'

    generator = described_class.new(cdn_host: 'cdn.test', secret_key: secret_key, ttl: 300, algorithm: 'sha256')

    signature_data = "exp=1300~acl=/#{uuid}/*"
    secret_key_bin = Array(secret_key.delete(" \t\r\n")).pack('H*')
    expected_hmac = OpenSSL::HMAC.hexdigest('sha256', secret_key_bin, signature_data)
    expected = "https://cdn.test/#{uuid}/?token=exp=1300~acl=/#{uuid}/*~hmac=#{expected_hmac}"

    expect(generator.generate_url(uuid, 'ignored', wildcard: true)).to eq(expected)
  end
end
