require 'spec_helper'

describe Uploadcare::Api do
  shared_examples 'respects :store option' do
    context 'respects :store option' do
      let(:upload_options) { {store: store} }
      subject { Array(uploaded).map(&:load_data) }

      context 'when :store option is true' do
        let(:store) { true }
        it { is_expected.to all(be_stored) }
      end

      define_negated_matcher :be_not_stored, :be_stored
      context 'when :store option is false' do
        let(:store) { false }
        it { is_expected.to all(be_not_stored) }
      end
    end
  end

  let(:api) { API }
  let(:upload_options) { {} }

  context 'when uploading single object' do
    subject(:uploaded) { api.upload(object, upload_options) }

    context 'when uploading a file' do
      let(:object) { FILE1 }

      it { is_expected.to be_a(Uploadcare::Api::File) }
      it { is_expected.to have_attributes(uuid: match(UUID_REGEX)) }
      include_examples 'respects :store option'
    end

    context 'when uploading from url' do
      let(:object) { IMAGE_URL }

      it { is_expected.to be_a(Uploadcare::Api::File) }
      it { is_expected.to have_attributes(uuid: match(UUID_REGEX)) }
      it { expect { api.upload('invalid.url.') }.to raise_error(ArgumentError) }
      include_examples 'respects :store option'
    end
  end

  context 'when loading multiple objects' do
    before(:all) { @uploaded_files = API.upload(FILES_ARY) }
    subject(:uploaded) { @uploaded_files.dup }

    it { is_expected.to be_a(Array) }
    it { is_expected.to all(be_a(Uploadcare::Api::File)) }
    it { is_expected.to all(have_attributes(uuid: match(UUID_REGEX))) }
    it { expect { uploaded.map(&:load_data) }.not_to raise_error }
  end

  context 'when given object is not a File, Array or String' do
    it { expect { api.upload(12) }.to raise_error(ArgumentError) }
  end
end
