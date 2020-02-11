require 'spec_helper'

module Uploadcare
  RSpec.describe SimpleAuthHeader do
    describe 'Uploadcare.Simple' do
      before do
        Uploadcare::PUBLIC_KEY = 'foo'
        Uploadcare::SECRET_KEY = 'bar'
        Uploadcare::AUTH_TYPE = 'Uploadcare.Simple'
      end

      it 'returns correct headers for simple authentication' do
        expect(Uploadcare::SimpleAuthHeader.call).to eq({ 'Authorization': "Uploadcare.Simple foo:bar" })
      end
    end
  end
end
