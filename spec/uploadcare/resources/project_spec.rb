# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Project do
  describe '.show' do
    let(:project_response) do
      {
        'name' => 'Test Project',
        'pub_key' => 'public_key',
        'autostore_enabled' => true,
        'collaborators' => [
          { 'name' => 'John Doe', 'email' => 'john.doe@example.com' },
          { 'name' => 'Jane Smith', 'email' => 'jane.smith@example.com' }
        ]
      }
    end

    before do
      allow_any_instance_of(Uploadcare::ProjectClient).to receive(:show).and_return(project_response)
    end

    it 'fetches project information and populates attributes' do
      project = described_class.show
      expect(project).to be_a(described_class)
      expect(project.name).to eq('Test Project')
      expect(project.pub_key).to eq('public_key')
      expect(project.autostore_enabled).to be(true)
      expect(project.collaborators).to be_an(Array)
      expect(project.collaborators.first['name']).to eq('John Doe')
      expect(project.collaborators.first['email']).to eq('john.doe@example.com')
    end
  end
end
