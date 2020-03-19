# frozen_string_literal: true

require 'spec_helper'
require 'param/user_agent'

module Uploadcare
  RSpec.describe Param::UserAgent do
    subject { Param::UserAgent }

    it 'contains gem version' do
      user_agent_string = subject.call
      expect(user_agent_string).to include(Uploadcare::VERSION)
    end

    it 'contains framework data when it is specified' do
      Uploadcare.config.framework_data = 'Rails'
      expect(subject.call).to include('; Rails')
      Uploadcare.config.framework_data = ''
      expect(subject.call).not_to include(';')
    end
  end
end
