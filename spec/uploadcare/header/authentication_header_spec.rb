require 'spec_helper'

RSpec.describe Uploadcare::AuthenticationHeader do
  describe 'Uploadcare.Simple' do
    before do
      Uploadcare::PUBLIC_KEY = 'foo'
      Uploadcare::SECRET_KEY = 'bar'
      Uploadcare::AUTH_TYPE = 'Uploadcare.Simple'
    end

    it 'returns correct headers for simple authentication' do
      expect(Uploadcare::AuthenticationHeader.call).to eq({ 'Authorization': "Uploadcare.Simple foo:bar" })
    end
  end

  describe 'Uploadcare' do
    before do
      Uploadcare::PUBLIC_KEY = 'foo'
      Uploadcare::SECRET_KEY = 'bar'
      Uploadcare::AUTH_TYPE = 'Uploadcare'
    end

    it 'returns correct headers for complex authentication'
  end
end
