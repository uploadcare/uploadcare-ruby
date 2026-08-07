# frozen_string_literal: true

require 'spec_helper'
require_relative '../../api_examples/support/example_helper'

RSpec.describe ApiExamples::ExampleHelper do
  describe '.wait_for_file_search' do
    let(:files) { instance_double(Uploadcare::Client::FilesAccessor) }
    let(:client) { instance_double(Uploadcare::Client, files: files) }
    let(:match) { instance_double(Uploadcare::Resources::File, uuid: 'file-uuid') }

    before do
      allow(described_class).to receive(:client).and_return(client)
      allow(described_class).to receive(:sleep)
    end

    it 'retries until the uploaded file appears' do
      found_matches = [match]
      allow(files).to receive(:search)
        .with(query: 'file-uuid', limit: 20)
        .and_return([], found_matches)

      result = described_class.wait_for_file_search(
        uuid: 'file-uuid', timeout: 1, poll_interval: 0
      )

      expect(result).to equal(found_matches)
      expect(files).to have_received(:search).twice
      expect(described_class).to have_received(:sleep).with(0).once
    end

    it 'raises after the timeout expires' do
      allow(files).to receive(:search).and_return([])

      expect do
        described_class.wait_for_file_search(uuid: 'file-uuid', timeout: 0, poll_interval: 0)
      end.to raise_error(RuntimeError, 'Timed out waiting for file file-uuid to appear in search')
    end
  end
end
