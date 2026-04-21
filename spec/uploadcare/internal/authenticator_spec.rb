# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Internal::Authenticator do
  let(:public_key) { 'test-public-key' }
  let(:secret_key) { 'test-secret-key' }

  let(:config) do
    Uploadcare::Configuration.new(
      public_key: public_key,
      secret_key: secret_key,
      auth_type: auth_type
    )
  end

  subject(:authenticator) { described_class.new(config: config) }

  describe '#initialize' do
    let(:auth_type) { 'Uploadcare.Simple' }

    it 'sets default headers with Accept and User-Agent' do
      headers = authenticator.default_headers
      expect(headers['Accept']).to eq('application/vnd.uploadcare-v0.7+json')
      expect(headers['User-Agent']).to include('UploadcareRuby/')
      expect(headers['User-Agent']).to include(public_key)
    end
  end

  describe '#headers' do
    context 'with simple auth' do
      let(:auth_type) { 'Uploadcare.Simple' }

      it 'returns headers with simple authorization' do
        result = authenticator.headers('GET', '/files/')
        expect(result['Authorization']).to eq("Uploadcare.Simple #{public_key}:#{secret_key}")
      end

      it 'includes Content-Type defaulting to application/json' do
        result = authenticator.headers('GET', '/files/')
        expect(result['Content-Type']).to eq('application/json')
      end

      it 'uses custom content_type when provided' do
        result = authenticator.headers('GET', '/files/', '', 'multipart/form-data')
        expect(result['Content-Type']).to eq('multipart/form-data')
      end

      it 'includes default headers' do
        result = authenticator.headers('GET', '/files/')
        expect(result['Accept']).to eq('application/vnd.uploadcare-v0.7+json')
        expect(result['User-Agent']).to include('UploadcareRuby/')
      end

      it 'raises AuthError when secret_key is blank' do
        blank_config = Uploadcare::Configuration.new(
          public_key: public_key,
          secret_key: '',
          auth_type: 'Uploadcare.Simple'
        )
        auth = described_class.new(config: blank_config)
        expect { auth.headers('GET', '/files/') }.to raise_error(
          Uploadcare::Exception::AuthError, /Secret Key is blank/
        )
      end

      it 'raises AuthError when public_key is blank' do
        blank_config = Uploadcare::Configuration.new(
          public_key: '',
          secret_key: secret_key,
          auth_type: 'Uploadcare.Simple'
        )
        auth = described_class.new(config: blank_config)
        expect { auth.headers('GET', '/files/') }.to raise_error(
          Uploadcare::Exception::AuthError, /Public Key is blank/
        )
      end
    end

    context 'with secure auth' do
      let(:auth_type) { 'Uploadcare' }

      it 'returns headers with HMAC-signed authorization' do
        result = authenticator.headers('GET', '/files/', '')
        expect(result['Authorization']).to start_with("Uploadcare #{public_key}:")
      end

      it 'includes a Date header' do
        result = authenticator.headers('GET', '/files/', '')
        expect(result['Date']).to match(/\w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} GMT/)
      end

      it 'includes Content-Type header' do
        result = authenticator.headers('POST', '/files/', '{"key":"val"}')
        expect(result['Content-Type']).to eq('application/json')
      end

      it 'uses custom content_type when provided' do
        result = authenticator.headers('POST', '/files/', '', 'text/plain')
        expect(result['Content-Type']).to eq('text/plain')
      end

      it 'generates different signatures for different methods' do
        get_headers = authenticator.headers('GET', '/files/', '')
        post_headers = authenticator.headers('POST', '/files/', '')
        get_sig = get_headers['Authorization'].split(':').last
        post_sig = post_headers['Authorization'].split(':').last
        expect(get_sig).not_to eq(post_sig)
      end

      it 'generates different signatures for different URIs' do
        a = authenticator.headers('GET', '/files/', '')
        b = authenticator.headers('GET', '/groups/', '')
        sig_a = a['Authorization'].split(':').last
        sig_b = b['Authorization'].split(':').last
        expect(sig_a).not_to eq(sig_b)
      end

      it 'generates different signatures for different bodies' do
        a = authenticator.headers('POST', '/files/', '{"a":1}')
        b = authenticator.headers('POST', '/files/', '{"b":2}')
        sig_a = a['Authorization'].split(':').last
        sig_b = b['Authorization'].split(':').last
        expect(sig_a).not_to eq(sig_b)
      end

      it 'raises AuthError when secret_key is blank' do
        blank_config = Uploadcare::Configuration.new(
          public_key: public_key,
          secret_key: '',
          auth_type: 'Uploadcare'
        )
        auth = described_class.new(config: blank_config)
        expect { auth.headers('GET', '/files/') }.to raise_error(
          Uploadcare::Exception::AuthError, /Secret Key is blank/
        )
      end

      it 'raises AuthError when secret_key is nil' do
        nil_config = Uploadcare::Configuration.new(
          public_key: public_key,
          secret_key: nil,
          auth_type: 'Uploadcare'
        )
        auth = described_class.new(config: nil_config)
        expect { auth.headers('GET', '/files/') }.to raise_error(
          Uploadcare::Exception::AuthError, /Secret Key is blank/
        )
      end

      it 'raises AuthError when public_key is blank' do
        blank_pk_config = Uploadcare::Configuration.new(
          public_key: '',
          secret_key: secret_key,
          auth_type: 'Uploadcare'
        )
        auth = described_class.new(config: blank_pk_config)
        expect { auth.headers('GET', '/files/') }.to raise_error(
          Uploadcare::Exception::AuthError, /Public Key is blank/
        )
      end

      it 'raises AuthError when public_key is nil' do
        nil_pk_config = Uploadcare::Configuration.new(
          public_key: nil,
          secret_key: secret_key,
          auth_type: 'Uploadcare'
        )
        auth = described_class.new(config: nil_pk_config)
        expect { auth.headers('GET', '/files/') }.to raise_error(
          Uploadcare::Exception::AuthError, /Public Key is blank/
        )
      end

      it 'normalizes URI without leading slash' do
        with_slash = authenticator.headers('GET', '/files/', '')
        without_slash = authenticator.headers('GET', 'files/', '')
        sig_with = with_slash['Authorization'].split(':').last
        sig_without = without_slash['Authorization'].split(':').last
        expect(sig_with).to eq(sig_without)
      end

      it 'uses MD5 for body digest required by Uploadcare REST signing' do
        expect(authenticator.send(:body_digest, 'abc')).to eq(OpenSSL::Digest.new('MD5').hexdigest('abc'))
      end

      it 'uses SHA1 for HMAC signature required by Uploadcare REST signing' do
        expect(authenticator.send(:signature_digest).name).to eq('SHA1')
      end
    end
  end
end
