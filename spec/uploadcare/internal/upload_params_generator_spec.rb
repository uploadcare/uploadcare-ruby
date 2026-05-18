# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Internal::UploadParamsGenerator do
  describe '.call' do
    let(:config) do
      Uploadcare::Configuration.new(
        public_key: 'test-pub-key',
        secret_key: 'test-secret-key',
        sign_uploads: sign_uploads,
        upload_signature_lifetime: 600
      )
    end
    let(:sign_uploads) { false }

    context 'with default options' do
      it 'returns hash with UPLOADCARE_PUB_KEY' do
        result = described_class.call(options: {}, config: config)
        expect(result['UPLOADCARE_PUB_KEY']).to eq('test-pub-key')
      end

      it 'does not include UPLOADCARE_STORE when store is not specified' do
        result = described_class.call(options: {}, config: config)
        expect(result).not_to have_key('UPLOADCARE_STORE')
      end

      it 'does not include signature params when sign_uploads is false' do
        result = described_class.call(options: {}, config: config)
        expect(result).not_to have_key('signature')
        expect(result).not_to have_key('expire')
      end
    end

    context 'with store option' do
      it 'sets UPLOADCARE_STORE to "1" for true' do
        result = described_class.call(options: { store: true }, config: config)
        expect(result['UPLOADCARE_STORE']).to eq('1')
      end

      it 'sets UPLOADCARE_STORE to "0" for false' do
        result = described_class.call(options: { store: false }, config: config)
        expect(result['UPLOADCARE_STORE']).to eq('0')
      end

      it 'sets UPLOADCARE_STORE to "1" for integer 1' do
        result = described_class.call(options: { store: 1 }, config: config)
        expect(result['UPLOADCARE_STORE']).to eq('1')
      end

      it 'sets UPLOADCARE_STORE to "0" for integer 0' do
        result = described_class.call(options: { store: 0 }, config: config)
        expect(result['UPLOADCARE_STORE']).to eq('0')
      end

      it 'sets UPLOADCARE_STORE to "1" for string "1"' do
        result = described_class.call(options: { store: '1' }, config: config)
        expect(result['UPLOADCARE_STORE']).to eq('1')
      end

      it 'sets UPLOADCARE_STORE to "0" for string "0"' do
        result = described_class.call(options: { store: '0' }, config: config)
        expect(result['UPLOADCARE_STORE']).to eq('0')
      end

      it 'converts other values to string via to_s' do
        result = described_class.call(options: { store: 'auto' }, config: config)
        expect(result['UPLOADCARE_STORE']).to eq('auto')
      end

      it 'omits UPLOADCARE_STORE when store is nil' do
        result = described_class.call(options: { store: nil }, config: config)
        expect(result).not_to have_key('UPLOADCARE_STORE')
      end
    end

    context 'with metadata option' do
      it 'formats metadata keys as metadata[key]' do
        options = { metadata: { 'tag' => 'photo', 'source' => 'web' } }
        result = described_class.call(options: options, config: config)
        expect(result['metadata[tag]']).to eq('photo')
        expect(result['metadata[source]']).to eq('web')
      end

      it 'converts metadata values to strings' do
        options = { metadata: { count: 42 } }
        result = described_class.call(options: options, config: config)
        expect(result['metadata[count]']).to eq('42')
      end

      it 'handles symbol keys in metadata' do
        options = { metadata: { category: 'docs' } }
        result = described_class.call(options: options, config: config)
        expect(result['metadata[category]']).to eq('docs')
      end

      it 'skips metadata when nil' do
        result = described_class.call(options: { metadata: nil }, config: config)
        expect(result.keys.select { |k| k.start_with?('metadata[') }).to be_empty
      end

      it 'raises ArgumentError when metadata is not a hash' do
        expect do
          described_class.call(options: { metadata: 'invalid' }, config: config)
        end.to raise_error(ArgumentError, /metadata must be a hash/)
      end

      it 'handles empty metadata hash' do
        result = described_class.call(options: { metadata: {} }, config: config)
        expect(result.keys.select { |k| k.start_with?('metadata[') }).to be_empty
      end
    end

    context 'with explicit signature options' do
      it 'uses provided signature and expire' do
        options = { signature: 'abc123', expire: 9_999_999 }
        result = described_class.call(options: options, config: config)
        expect(result['signature']).to eq('abc123')
        expect(result['expire']).to eq(9_999_999)
      end

      it 'uses provided signature without expire' do
        options = { signature: 'abc123' }
        result = described_class.call(options: options, config: config)
        expect(result['signature']).to eq('abc123')
        expect(result).not_to have_key('expire')
      end

      it 'ignores sign_uploads config when explicit signature is provided' do
        sign_config = Uploadcare::Configuration.new(
          public_key: 'pk',
          secret_key: 'sk',
          sign_uploads: true,
          upload_signature_lifetime: 600
        )
        options = { signature: 'explicit-sig', expire: 12_345 }
        result = described_class.call(options: options, config: sign_config)
        expect(result['signature']).to eq('explicit-sig')
        expect(result['expire']).to eq(12_345)
      end
    end

    context 'with sign_uploads enabled in config' do
      let(:sign_uploads) { true }

      it 'generates signature and expire from SignatureGenerator' do
        allow(Uploadcare::Internal::SignatureGenerator).to receive(:call)
          .with(config: config)
          .and_return({ signature: 'generated-sig', expire: 1_700_000 })

        result = described_class.call(options: {}, config: config)
        expect(result['signature']).to eq('generated-sig')
        expect(result['expire']).to eq(1_700_000)
      end
    end

    context 'with combined options' do
      it 'includes all params together' do
        options = {
          store: true,
          metadata: { 'env' => 'test' },
          signature: 'combo-sig',
          expire: 12_345
        }
        result = described_class.call(options: options, config: config)
        expect(result['UPLOADCARE_PUB_KEY']).to eq('test-pub-key')
        expect(result['UPLOADCARE_STORE']).to eq('1')
        expect(result['metadata[env]']).to eq('test')
        expect(result['signature']).to eq('combo-sig')
        expect(result['expire']).to eq(12_345)
      end
    end
  end
end
