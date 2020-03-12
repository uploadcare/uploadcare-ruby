# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Param
    RSpec.describe UserAgent do
      it 'contains gem version' do
        user_agent_string = UserAgent.call
        expect(user_agent_string).to include(Uploadcare::VERSION)
      end

      it 'contains framework data when it is specified' do
        Uploadcare.configuration.framework_data = 'Rails'
        expect(UserAgent.call).to include('; Rails')
        Uploadcare.configuration.framework_data = ''
        expect(UserAgent.call).not_to include(';')
      end
    end
  end
end
