require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api::File do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
    @url = "http://macaw.co/images/macaw-logo.png"
  end

  it "basic list" do
    list = @api.get "/groups/"
    binding.pry
  end
end