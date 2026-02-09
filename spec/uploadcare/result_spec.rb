# frozen_string_literal: true

RSpec.describe Uploadcare::Result do
  it 'returns success result' do
    result = described_class.success('ok')

    expect(result.success?).to be(true)
    expect(result.failure?).to be(false)
    expect(result.success).to eq('ok')
    expect(result.value!).to eq('ok')
  end

  it 'returns failure result' do
    error = StandardError.new('boom')
    result = described_class.failure(error)

    expect(result.success?).to be(false)
    expect(result.failure?).to be(true)
    expect(result.failure).to eq(error)
    expect(result.error_message).to eq('boom')
  end

  it 'captures exceptions' do
    result = described_class.capture { raise StandardError, 'nope' }

    expect(result.failure?).to be(true)
    expect(result.error_message).to eq('nope')
  end

  it 'returns nil error_message when no error' do
    result = described_class.success('ok')

    expect(result.error_message).to be_nil
  end

  it 'handles non-exception errors' do
    result = described_class.failure('boom')

    expect(result.error_message).to eq('boom')
  end

  it 'unwraps non-result values' do
    expect(described_class.unwrap('raw')).to eq('raw')
  end

  it 'raises when accessing value on failure' do
    error = StandardError.new('nope')
    result = described_class.failure(error)

    expect { result.value! }.to raise_error(StandardError, 'nope')
  end

  it 'raises inspected value for non-exception errors' do
    error = { error: 'boom' }
    result = described_class.failure(error)

    expect { result.value! }.to raise_error(RuntimeError, /\{error: "boom"\}/)
  end
end
