# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe SimpleAuthHeader do
    describe 'Uploadcare.Simple' do
      before do
        Uploadcare.configuration.public_key = 'foo'
        Uploadcare.configuration.secret_key = 'bar'
        Uploadcare.configuration.auth_type = 'Uploadcare.Simple'
      end

      it 'returns correct headers for simple authentication' do
        expect(Uploadcare::SimpleAuthHeader.call).to eq('Authorization': 'Uploadcare.Simple foo:bar')
      end
    end
  end
end
