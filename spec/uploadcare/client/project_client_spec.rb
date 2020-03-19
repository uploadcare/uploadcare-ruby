# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe ProjectClient do
      before do
        Uploadcare.config.public_key = 'foo'
      end

      it 'requests info about target project' do
        VCR.use_cassette('project') do
          response = ProjectClient.new.show
          expect(response.value![:pub_key]).to eq(Uploadcare.config.public_key)
        end
      end
    end
  end
end
