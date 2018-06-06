require 'spec_helper'

describe Uploadcare do
  around do |example|
    orig_stderr = $stderr
    $stderr = StringIO.new

    example.call

    $stderr = orig_stderr
  end

  describe '::user_agent' do
    subject(:user_agent) { described_class.user_agent(options) }
    let(:options) { {user_agent: 'user/agent'} }
    let(:user_agent_builder) { instance_double('Uploadcare::UserAgent') }

    it 'returns user agent string' do
      allow(Uploadcare::UserAgent).to receive(:new) { user_agent_builder }
      expect(user_agent_builder).to receive(:call).with(options) { 'user/agent' }

      expect(user_agent).to eq('user/agent')
    end

    it 'is deprecated' do
      user_agent

      $stderr.rewind
      expect($stderr.string).to start_with('[DEPRECATION] `Uploadcare::user_agent`')
    end
  end

  describe '::USER_AGENT' do
    it { expect(described_class::USER_AGENT).not_to be_nil }

    it 'is deprecated' do
      described_class::USER_AGENT

      $stderr.rewind
      expect($stderr.string).to start_with('[DEPRECATION] `Uploadcare::USER_AGENT`')
    end
  end
end
