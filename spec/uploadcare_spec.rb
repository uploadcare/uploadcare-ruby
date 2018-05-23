require 'spec_helper'

describe Uploadcare do
  describe '::user_agent' do
    subject(:user_agent) { described_class.user_agent(options) }
    let(:options) { {user_agent: 'user/agent'} }
    let(:user_agent_builder) { instance_double('Uploadcare::UserAgent') }

    it 'returns user agent string' do
      allow(Uploadcare::UserAgent).to receive(:new) { user_agent_builder }
      expect(user_agent_builder).to receive(:call).with(options) { 'user/agent' }

      expect(user_agent).to eq('user/agent')
    end
  end
end
