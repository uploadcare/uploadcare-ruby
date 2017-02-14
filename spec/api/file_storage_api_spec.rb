require 'spec_helper'

describe Uploadcare::FileStorageApi do
  let(:api){ API }
  let(:file){ api.file_list(limit: 1).first || api.upload(IMAGE_URL) }

  shared_examples 'batch action on files' do
    let(:uuids) { ["dc2c175d-a3b5-4435-b4f4-fae77bbe5597", "cea319aa-6e17-4172-8722-8dd7c459a523"] }
    let(:files) { uuids.map { |uuid| Uploadcare::Api::File.new(api, uuid) } }
    let(:api_endpoint) { "/files/storage/" }

    it 'accepts array of uuids' do
      expect(api).to receive(http_method)
      expect { subject.call(uuids) }.not_to raise_error
    end

    it 'accepts enumerable containing Uploadcare::Api::File objects' do
      expect(api).to receive(http_method)
      expect { subject.call(files) }.not_to raise_error
    end

    it 'converts Uploadcare::Api::File-s to uuids' do
      expect(api).to receive(http_method).with(api_endpoint, uuids)
      subject.call(files)
    end

    context 'when input contains something other than UUIDs or Uploadcare::Api::File-s' do
      it 'raises ArgumentError' do
        ['not-an-uuid', nil, 1].each do |wrong_input_value|
          expect { subject.call([wrong_input_value]) }.to raise_error(ArgumentError)
        end
      end
    end

    it 'breaks large input arrays into batches' do
      stub_const("Uploadcare::FileStorageApi::BATCH_SIZE", 1)

      expect(api).to receive(http_method).with(api_endpoint, [uuids[0]]).ordered
      expect(api).to receive(http_method).with(api_endpoint, [uuids[1]]).ordered

      subject.call(uuids)
    end
  end

  describe '#store_files' do
    let(:http_method) { :put }
    subject { ->(objects) { api.store_files(objects) } }

    it_behaves_like 'batch action on files'

    describe 'integration test' do
      before { file.delete if file.stored? }

      it 'stores files with given uuids' do
        expect { api.store_files([file]) }
          .to change { file.load!.stored? }.from(false).to(true)
      end
    end
  end

  describe '#delete_files' do
    let(:http_method) { :delete }
    subject { ->(objects) { api.delete_files(objects) } }

    it_behaves_like 'batch action on files'

    describe 'integration test' do
      before { file.store if file.deleted? }

      it 'deletes files with given uuids' do
        expect { api.delete_files([file]) }
          .to change { file.load!.deleted? }.from(false).to(true)
      end
    end
  end
end
