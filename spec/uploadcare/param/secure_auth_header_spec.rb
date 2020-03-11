# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe SecureAuthHeader do
    describe 'signature' do
      before(:each) do
        allow(Time).to receive(:now).and_return(Time.parse('2017.02.02 12:58:50 +0000'))
        Uploadcare.configuration.public_key = 'pub'
        Uploadcare.configuration.secret_key = 'priv'
      end

      it 'returns correct headers for complex authentication' do
        headers = Uploadcare::SecureAuthHeader.call(method: 'POST',
                                                    uri: '/path', content_type: 'application/x-www-form-urlencoded')
        expected = '47af79c7f800de03b9e0f2dbb1e589cba7b210c2'
        expect(headers[:Authorization]).to eq "Uploadcare pub:#{expected}"
      end
    end
  end
end
