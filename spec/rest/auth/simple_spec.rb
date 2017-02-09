require 'spec_helper'

describe Uploadcare::Connections::Auth::Simple do
  let(:env){ Faraday::Env.new(nil, nil, nil, nil, {}) }
  subject{ described_class.new(public_key: 'pub', private_key: 'priv') }

  describe 'apply' do
    it "adds Authorization header to env's request_headers" do
      subject.apply(env)
      expect(env.request_headers).to include('Authorization')
    end

    it "sets Authorization header's value correctly" do
      subject.apply(env)
      expect(env.request_headers['Authorization']).to eq "Uploadcare.Simple pub:priv"
    end
  end

  describe 'integration' do
    let(:api){ Uploadcare::Api.new(auth_scheme: :simple) }

    before(:each) do
      # ensure that simple auth is being used
      expect_any_instance_of(described_class).to receive(:apply).and_call_original
    end

    it 'auth works with real requests' do
      expect{ api.get('/files/') }.not_to raise_error
    end
  end
end
