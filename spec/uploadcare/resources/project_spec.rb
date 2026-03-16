# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Resources::Project do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:rest) { instance_double(Uploadcare::Api::Rest) }
  let(:rest_project) { instance_double(Uploadcare::Api::Rest::Project) }
  let(:api) { instance_double(Uploadcare::Client::Api, rest: rest) }

  let(:project_attrs) do
    {
      'name' => 'My Project',
      'pub_key' => 'demopublickey',
      'autostore_enabled' => true,
      'collaborators' => [
        { 'name' => 'Alice', 'email' => 'alice@example.com' }
      ]
    }
  end

  before do
    allow(client).to receive(:api).and_return(api)
    allow(rest).to receive(:project).and_return(rest_project)
  end

  describe '.current' do
    it 'fetches current project info' do
      allow(rest_project).to receive(:show)
        .with(request_options: {})
        .and_return(Uploadcare::Result.success(project_attrs))

      project = described_class.current(client: client)
      expect(project).to be_a(described_class)
      expect(project.name).to eq('My Project')
      expect(project.pub_key).to eq('demopublickey')
      expect(project.autostore_enabled).to be true
      expect(project.collaborators).to be_an(Array)
      expect(project.collaborators.first['name']).to eq('Alice')
    end

    it 'is aliased as show' do
      expect(described_class).to respond_to(:show)
    end
  end

  describe 'attributes' do
    it 'exposes name, pub_key, autostore_enabled, collaborators' do
      project = described_class.new(project_attrs, client)
      expect(project.name).to eq('My Project')
      expect(project.pub_key).to eq('demopublickey')
      expect(project.autostore_enabled).to be true
      expect(project.collaborators).to be_an(Array)
    end
  end
end
