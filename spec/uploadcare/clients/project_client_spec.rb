# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::ProjectClient do
  subject(:client) { described_class.new }

  describe '#show' do
    let(:response_body) do
      {
        'name' => 'My Project',
        'pub_key' => 'project_public_key',
        'collaborators' => [
          {
            'email' => 'admin@example.com',
            'name' => 'Admin'
          }
        ]
      }
    end

    before do
      stub_request(:get, 'https://api.uploadcare.com/project/')
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the project details' do
      response = client.show
      expect(response).to eq(response_body)
    end
  end
end
