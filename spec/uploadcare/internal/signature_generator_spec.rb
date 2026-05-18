# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Internal::SignatureGenerator do
  describe '.call' do
    let(:config) do
      Uploadcare::Configuration.new(
        public_key: 'test-public',
        secret_key: secret_key,
        upload_signature_lifetime: lifetime
      )
    end

    context 'with valid config' do
      let(:secret_key) { 'my-secret-key' }
      let(:lifetime) { 600 }

      it 'returns a hash with :signature and :expire keys' do
        result = described_class.call(config: config)
        expect(result).to be_a(Hash)
        expect(result).to have_key(:signature)
        expect(result).to have_key(:expire)
      end

      it 'returns a hex string signature' do
        result = described_class.call(config: config)
        expect(result[:signature]).to match(/\A[a-f0-9]{64}\z/)
      end

      it 'returns an expire timestamp in the future' do
        result = described_class.call(config: config)
        expect(result[:expire]).to be > Time.now.to_i
        expect(result[:expire]).to be <= Time.now.to_i + lifetime + 1
      end

      it 'generates a valid HMAC-SHA256 signature' do
        now = Time.now.to_i
        allow(Time).to receive(:now).and_return(Time.at(now))

        result = described_class.call(config: config)
        expected_expire = now + lifetime
        expected_sig = OpenSSL::HMAC.hexdigest('sha256', secret_key, expected_expire.to_s)

        expect(result[:expire]).to eq(expected_expire)
        expect(result[:signature]).to eq(expected_sig)
      end

      it 'generates different signatures for different secret keys' do
        config_a = Uploadcare::Configuration.new(
          public_key: 'pk', secret_key: 'key-a', upload_signature_lifetime: 600
        )
        config_b = Uploadcare::Configuration.new(
          public_key: 'pk', secret_key: 'key-b', upload_signature_lifetime: 600
        )

        now = Time.now.to_i
        allow(Time).to receive(:now).and_return(Time.at(now))

        result_a = described_class.call(config: config_a)
        result_b = described_class.call(config: config_b)

        expect(result_a[:signature]).not_to eq(result_b[:signature])
      end
    end

    context 'with empty secret_key' do
      let(:secret_key) { '' }
      let(:lifetime) { 600 }

      it 'raises ArgumentError' do
        expect { described_class.call(config: config) }.to raise_error(
          ArgumentError, /secret_key is required/
        )
      end
    end

    context 'with nil secret_key' do
      let(:secret_key) { nil }
      let(:lifetime) { 600 }

      it 'raises ArgumentError' do
        expect { described_class.call(config: config) }.to raise_error(
          ArgumentError, /secret_key is required/
        )
      end
    end

    context 'with invalid lifetime' do
      let(:secret_key) { 'my-secret' }

      context 'when lifetime is zero' do
        let(:lifetime) { 0 }

        it 'raises ArgumentError' do
          expect { described_class.call(config: config) }.to raise_error(
            ArgumentError, /upload_signature_lifetime must be a positive Integer/
          )
        end
      end

      context 'when lifetime is negative' do
        let(:lifetime) { -10 }

        it 'raises ArgumentError' do
          expect { described_class.call(config: config) }.to raise_error(
            ArgumentError, /upload_signature_lifetime must be a positive Integer/
          )
        end
      end

      context 'when lifetime is a float' do
        let(:lifetime) { 30.5 }

        it 'raises ArgumentError' do
          expect { described_class.call(config: config) }.to raise_error(
            ArgumentError, /upload_signature_lifetime must be a positive Integer/
          )
        end
      end

      context 'when lifetime is a string' do
        let(:lifetime) { '600' }

        it 'raises ArgumentError' do
          expect { described_class.call(config: config) }.to raise_error(
            ArgumentError, /upload_signature_lifetime must be a positive Integer/
          )
        end
      end
    end
  end
end
