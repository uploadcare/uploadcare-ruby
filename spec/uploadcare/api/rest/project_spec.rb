# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api::Rest::Project do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end

  let(:rest) { Uploadcare::Api::Rest.new(config: config) }

  subject(:project) { described_class.new(rest: rest) }

  describe '#initialize' do
    it 'stores the rest client' do
      expect(project.rest).to eq(rest)
    end
  end

  describe '#show' do
    before do
      stub_request(:get, 'https://api.uploadcare.com/project/')
        .to_return(
          status: 200,
          body: {
            name: 'Demo Project',
            pub_key: 'demopublickey',
            autostore_enabled: true,
            collaborators: [
              { name: 'User One', email: 'user1@example.com' }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns project details' do
      result = project.show

      expect(result).to be_success
      expect(result.value!['name']).to eq('Demo Project')
      expect(result.value!['pub_key']).to eq('demopublickey')
      expect(result.value!['autostore_enabled']).to be true
    end

    it 'includes collaborator information' do
      result = project.show

      expect(result).to be_success
      collaborators = result.value!['collaborators']
      expect(collaborators.length).to eq(1)
      expect(collaborators.first['email']).to eq('user1@example.com')
    end

    it 'returns a failure Result on authentication error' do
      stub_request(:get, 'https://api.uploadcare.com/project/')
        .to_return(
          status: 401,
          body: { detail: 'Authentication credentials were not provided.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = project.show

      expect(result).to be_failure
      expect(result.error).to be_a(Uploadcare::Exception::RequestError)
    end
  end
end
