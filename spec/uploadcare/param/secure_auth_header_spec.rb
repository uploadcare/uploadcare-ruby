# frozen_string_literal: true

require 'spec_helper'
require 'param/secure_auth_header'

module Uploadcare
  RSpec.describe Param::SecureAuthHeader do
    subject { Param::SecureAuthHeader }
    describe 'signature' do
      before(:each) do
        allow(Time).to receive(:now).and_return(Time.parse('2017.02.02 12:58:50 +0000'))
        Uploadcare.config.public_key = 'pub'
        Uploadcare.config.secret_key = 'priv'
      end

      it 'returns correct headers for complex authentication' do
        headers = subject.call(method: 'POST', uri: '/path', content_type: 'application/x-www-form-urlencoded')
        expected = '47af79c7f800de03b9e0f2dbb1e589cba7b210c2'
        expect(headers[:Authorization]).to eq "Uploadcare pub:#{expected}"
      end
    end
  end
end
