# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Param
    RSpec.describe UserAgent do
      it 'contains gem version' do
        user_agent_string = UserAgent.call
        expect(user_agent_string).to include(Uploadcare::VERSION)
      end
    end
  end
end
