# frozen_string_literal: true

require 'spec_helper'
require 'param/authentication_header'

module Uploadcare
  RSpec.describe Param::AuthenticationHeader do
    subject { Param::AuthenticationHeader }

    before do
      allow(Param::SimpleAuthHeader).to receive(:call).and_return('SimpleAuth called')
      allow(Param::SecureAuthHeader).to receive(:call).and_return('SecureAuth called')
    end

    it 'decides which header to use depending on configuration' do
      Uploadcare.config.auth_type = 'Uploadcare.Simple'
      expect(subject.call).to eq('SimpleAuth called')
      Uploadcare.config.auth_type = 'Uploadcare'
      expect(subject.call).to eq('SecureAuth called')
    end

    it 'raise argument error if public_key is blank' do
      Uploadcare.config.public_key = ''
      expect { subject.call }.to raise_error(AuthError, 'Public Key is blank.')
    end

    it 'raise argument error if secret_key is blank' do
      Uploadcare.config.secret_key = ''
      expect { subject.call }.to raise_error(AuthError, 'Secret Key is blank.')
    end
  end
end
