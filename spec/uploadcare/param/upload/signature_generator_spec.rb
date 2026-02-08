# frozen_string_literal: true

require 'digest'

RSpec.describe Uploadcare::Param::Upload::SignatureGenerator do
  it 'returns signature and expire' do
    allow(Time).to receive(:now).and_return(Time.at(1000))
    config = Uploadcare::Configuration.new(secret_key: 'secret', upload_signature_lifetime: 30)

    result = described_class.call(config: config)

    expect(result[:expire]).to eq(1030)
    expected_signature = Digest::MD5.hexdigest('secret1030')
    expect(result[:signature]).to eq(expected_signature)
  end

  it 'handles nil secret key' do
    allow(Time).to receive(:now).and_return(Time.at(1000))
    config = Uploadcare::Configuration.new(secret_key: nil, upload_signature_lifetime: 30)

    result = described_class.call(config: config)

    expect(result[:expire]).to eq(1030)
    expected_signature = Digest::MD5.hexdigest('1030')
    expect(result[:signature]).to eq(expected_signature)
  end
end
