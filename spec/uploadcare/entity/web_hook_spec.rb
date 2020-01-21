require 'spec_helper'

module Uploadcare
  RSpec.describe Webhook do
    subject { Webhook }
    it 'responds to expected methods' do
      %i[list delete].each do |method|
        expect(subject).to respond_to(method)
      end
    end
  end
end
