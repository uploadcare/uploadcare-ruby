# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Authenticator do
  let(:public_key) { 'test_public_key' }
  let(:secret_key) { 'test_secret_key' }
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: public_key,
      secret_key: secret_key,
      auth_type: auth_type
    )
  end
  let(:authenticator) { described_class.new(config) }
  let(:http_method) { 'GET' }
  let(:uri) { '/files/?limit=1&stored=true' }
  let(:body) { '' }

  describe '#headers' do
    context 'when using Uploadcare.Simple auth' do
      let(:auth_type) { 'Uploadcare.Simple' }

      it 'returns correct headers with Authorization' do
        headers = authenticator.headers(http_method, uri, body)
        expect(headers['Authorization']).to eq("Uploadcare.Simple #{public_key}:#{secret_key}")
        expect(headers['Accept']).to eq('application/vnd.uploadcare-v0.7+json')
        expect(headers['Content-Type']).to eq('application/json')
        expect(headers).not_to have_key('Date')
      end
    end

    context 'when using Uploadcare auth' do
      let(:auth_type) { 'Uploadcare' }

      before { allow(Time).to receive(:now).and_return(Time.at(0)) }

      it 'returns correct headers with computed signature and Date' do
        headers = authenticator.headers(http_method, uri, body)
        date = Time.now.httpdate
        content_md5 = Digest::MD5.hexdigest(body)
        content_type = 'application/json'
        expected_string_to_sign = [
          http_method,
          content_md5,
          content_type,
          date,
          uri
        ].join("\n")
        expected_signature = OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new('sha1'),
          secret_key,
          expected_string_to_sign
        )
        expect(headers['Authorization']).to eq("Uploadcare #{public_key}:#{expected_signature}")
        expect(headers['Date']).to eq(date)
        expect(headers['Accept']).to eq('application/vnd.uploadcare-v0.7+json')
        expect(headers['Content-Type']).to eq('application/json')
      end
    end
  end
end
