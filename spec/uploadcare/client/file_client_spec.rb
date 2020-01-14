require 'spec_helper'

RSpec.describe Uploadcare::FileClient do
  it 'makes a request' do
    stub = stub_request(:get, "https://api.uploadcare.com/files/")
    Uploadcare::FileClient.new.index
    assert_requested(stub)
  end

  describe 'authentication' do
    it 'performs a simple authentication' do
      # byebug
    end

    it 'performs Uploadcare authentication'
  end
end
