require 'spec_helper'

describe Uploadcare do

  describe '::user_agent' do
    context "if :user_agent is specified in method's options" do
      it "returns it's stringified version" do
        expect( Uploadcare.user_agent(user_agent: 123) ).to eq '123'
      end
    end

    context "if user_agent is not specified in method's options" do
      it 'builds user-agent from ruby version, gem version and public key' do
        expected = /#{Gem.ruby_version}\/#{described_class::VERSION}\/test/
        expect( Uploadcare.user_agent(public_key: 'test') ).to match(expected)
      end
    end
  end

end
