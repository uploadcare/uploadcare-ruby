require 'spec_helper'

module Uploadcare
  RSpec.describe File do
    it 'responds to expected methods' do
      %i[index info copy delete].each do |method|
        expect(File).to respond_to(method)
      end
    end
  end
end
