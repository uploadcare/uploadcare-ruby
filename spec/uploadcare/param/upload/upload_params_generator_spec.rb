# frozen_string_literal: true

RSpec.describe Uploadcare::Param::Upload::UploadParamsGenerator do
  it 'builds params with metadata' do
    config = Uploadcare::Configuration.new(public_key: 'pub')
    params = described_class.call(options: { metadata: { foo: 'bar' } }, config: config)

    expect(params['UPLOADCARE_PUB_KEY']).to eq('pub')
    expect(params['metadata[foo]']).to eq('bar')
  end

  it 'adds signature when enabled' do
    config = Uploadcare::Configuration.new(public_key: 'pub', sign_uploads: true)
    allow(Uploadcare::Param::Upload::SignatureGenerator).to receive(:call).and_return({ signature: 'sig', expire: 123 })

    params = described_class.call(options: {}, config: config)

    expect(params['signature']).to eq('sig')
    expect(params['expire']).to eq(123)
  end

  it 'sets store to 1 for true' do
    config = Uploadcare::Configuration.new(public_key: 'pub')
    params = described_class.call(options: { store: true }, config: config)

    expect(params['UPLOADCARE_STORE']).to eq('1')
  end

  it 'sets store to 0 for false' do
    config = Uploadcare::Configuration.new(public_key: 'pub')
    params = described_class.call(options: { store: false }, config: config)

    expect(params['UPLOADCARE_STORE']).to eq('0')
  end

  it 'passes through store values' do
    config = Uploadcare::Configuration.new(public_key: 'pub')
    params = described_class.call(options: { store: 'auto' }, config: config)

    expect(params['UPLOADCARE_STORE']).to eq('auto')
  end

  it 'uses explicit signature params when provided' do
    config = Uploadcare::Configuration.new(public_key: 'pub', sign_uploads: true)
    params = described_class.call(options: { signature: 'sig', expire: 123 }, config: config)

    expect(params['signature']).to eq('sig')
    expect(params['expire']).to eq(123)
  end

  it 'supports non-hash signature data' do
    config = Uploadcare::Configuration.new(public_key: 'pub', sign_uploads: true)
    allow(Uploadcare::Param::Upload::SignatureGenerator).to receive(:call).and_return('signature-string')

    params = described_class.call(options: {}, config: config)

    expect(params['signature']).to eq('signature-string')
    expect(params['expire']).to be_nil
  end

  it 'converts metadata values to strings' do
    config = Uploadcare::Configuration.new(public_key: 'pub')
    params = described_class.call(options: { metadata: { count: 12 } }, config: config)

    expect(params['metadata[count]']).to eq('12')
  end

  it 'raises when metadata is not a hash' do
    config = Uploadcare::Configuration.new(public_key: 'pub')

    expect do
      described_class.call(options: { metadata: 'nope' }, config: config)
    end.to raise_error(ArgumentError, 'metadata must be a hash')
  end
end
