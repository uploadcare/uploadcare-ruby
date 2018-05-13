require 'spec_helper'

describe Uploadcare::UserAgent do
  subject(:user_agent) { described_class.new.call(options) }

  before do
    stub_const('Uploadcare::VERSION', '123')
    allow(Gem).to receive(:ruby_version) { '456' }
  end

  context 'when user_agent option is set' do
    let(:options) do
      { user_agent: 'predefined user agent' }
    end

    it { is_expected.to eq('predefined user agent') }
  end

  context 'when user_agent_extension option is set' do
    let(:options) do
      { public_key: 'pubkey', user_agent_extension: 'ext' }
    end

    it { is_expected.to eq('UploadcareRuby/123/pubkey (Ruby/456; ext)') }
  end

  context 'when user_agent_extension option is not set' do
    let(:options) do
      { public_key: 'pubkey' }
    end

    it { is_expected.to eq('UploadcareRuby/123/pubkey (Ruby/456;)') }
  end
end
