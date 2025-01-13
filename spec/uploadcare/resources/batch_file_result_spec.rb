# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::BatchFileResult do
  let(:file_data) { { 'uuid' => SecureRandom.uuid, 'original_filename' => 'file.jpg' } }
  let(:response) do
    {
      status: 200,
      result: [file_data],
      problems: [{ 'some-uuid': 'Missing in the project' }]
    }
  end
  let(:config) { Uploadcare.configuration }
  let(:result) { [file_data] }

  subject do
    described_class.new(
      **response,
      config: config
    )
  end

  it 'initializes with status, result, and problems' do
    expect(subject.status).to eq(200)
    expect(subject.result).to all(be_an(Uploadcare::File))
    expect(subject.problems).to eq(response[:problems])
  end
end
