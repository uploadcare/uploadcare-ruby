# frozen_string_literal: true

RSpec.describe Uploadcare::SignedUrlGenerators::BaseGenerator do
  it 'raises not implemented' do
    generator = described_class.new(cdn_host: 'example.com', secret_key: 'abc')

    expect { generator.generate_url }.to raise_error(NotImplementedError)
  end
end
