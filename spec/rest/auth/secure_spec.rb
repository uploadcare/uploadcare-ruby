require 'spec_helper'

describe Uploadcare::Connections::Auth::Secure do
  describe '#apply' do
    let(:env){ Faraday::Env.new(:get, nil, URI::HTTP.build(host: 'example.com'), nil, {}) }
    subject{ env.request_headers }

    before(:each) do
      described_class.new(public_key: 'pub', private_key: 'priv').apply(env)
    end

    it "adds Authorization header to env's request_headers" do
      expect(subject).to include('Authorization')
    end

    it "adds Date header to env's request_headers" do
      expect(subject).to include('Date')
    end

    it "uses secure authorization" do
      expect(subject['Authorization']).to match /Uploadcare pub:.+/
    end
  end

  describe 'signature' do
    let(:uri){ URI::HTTP.build(host: 'example.com', path: '/path', query: 'test=1') }
    let(:headers){ {'Content-Type' => 'application/x-www-form-urlencoded'} }
    let(:env){ Faraday::Env.new(:post, 'url=encoded&test=body', uri, nil, headers) }

    subject{ env.request_headers }

    before(:each) do
      allow(Time).to receive(:now).and_return(Time.parse('2017.02.02 12:58:50 +0000'))
      described_class.new(public_key: 'pub', private_key: 'priv').apply(env)
    end

    it "counts signature correctly" do
      expected = '71b61ed67d16f48d2e46a4ee72ca12025aeb8d1f'
      expect(subject['Authorization']).to eq "Uploadcare pub:#{expected}"
    end
  end


  describe 'integration' do
    let(:api){ Uploadcare::Api.new(auth_scheme: :secure) }
    let(:file){ api.upload IMAGE_URL }

    before(:each) do
      # ensure that secure auth is being used
      expect_any_instance_of(described_class).to receive(:apply).at_least(4).times.and_call_original
    end

    it 'auth works with real requests' do
      # request with url params
      expect{ api.get('/files/', limit: 1) }.not_to raise_error
      # request with an url-encoded body
      expect{
        retry_if(Uploadcare::Error::RequestError::BadRequest) do
          api.post('/files/', source: file.uuid)
        end
      }.not_to raise_error
      # request with an empty body and a redirect
      expect{ api.delete("/files/#{file.uuid}/storage/") }.not_to raise_error
    end
  end
end
