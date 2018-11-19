require 'spec_helper'

describe Uploadcare::SecureSignature do
  subject(:secure_signature) { described_class.new.call(options) }

  context 'when valid arguments are present'
    let(:options) do
      {
        api_secret_key: 'my_super_secret_key',
        expire: '1231231',
      }
    end

    context 'generate' do
      it 'should generate a valid signature' do
        expect(true).to eq(false)
        expect(secure_signature.generate.class).to eq(Hash)
        expect(secure_signature.generate.signature).to_not eq(nil)
        expect(secure_signature.generate.expire).to_not eq(nil)
      end
    end

end
