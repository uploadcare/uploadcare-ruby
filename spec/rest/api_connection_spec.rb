require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Connections::ApiConnection do
  let(:settings){ Uploadcare.default_settings }

  it 'is initializable with default settings' do
    expect {described_class.new(settings)}.to_not raise_error
  end


  describe 'default request headers' do
    subject{ described_class.new(settings).headers }

    it 'includes correct Accept header' do
      expected = "application/vnd.uploadcare-v#{settings[:api_version]}+json"
      expect(subject['Accept']).to eq expected
    end

    it 'includes correct User-Agent header' do
      expected = Uploadcare::UserAgent.new.call(settings)
      expect(subject['User-Agent']).to eq expected
    end
  end


  describe 'middleware' do
    subject{ described_class.new(settings).builder.handlers }

    it 'uses Request::Auth middleware' do
      expect(subject).to include(Uploadcare::Connections::Request::Auth)
    end

    it 'uses Response::ParseJson middleware' do
      expect(subject).to include(Uploadcare::Connections::Response::ParseJson)
    end

    it 'uses Response::RaiseError middleware' do
      expect(subject).to include(Uploadcare::Connections::Response::RaiseError)
    end
  end


  describe 'auth scheme' do
    it 'uses simple auth when auth_scheme: :simple setting is provided' do
      expect(Uploadcare::Connections::Auth::Simple).to receive(:new)
      described_class.new(settings.merge(auth_scheme: :simple))
    end

    it 'uses secure auth when auth_scheme: :secure setting is provided' do
      expect(Uploadcare::Connections::Auth::Secure).to receive(:new)
      described_class.new(settings.merge(auth_scheme: :secure))
    end

    it 'raises KeyError when :auth_scheme options is not provided' do
      expect{
        described_class.new(settings.reject{|k,_| k == :auth_scheme})
      }.to raise_error(KeyError)
    end

    it 'raises ArgumentError when provided :auth_scheme is unknown' do
      expect{
        described_class.new(settings.merge(auth_scheme: :unknown))
      }.to raise_error(ArgumentError)
    end
  end
end
