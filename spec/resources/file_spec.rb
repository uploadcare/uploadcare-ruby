require 'spec_helper'
require 'uri'
require 'socket'
require 'securerandom'

describe Uploadcare::Api::File do
  let(:api) { API }
  let(:file) { api.upload IMAGE_URL }

  it 'is an instance of File' do
    expect(file).to be_an_instance_of Uploadcare::Api::File
  end

  it 'is not initialized without correct UUID given' do
    expect {Uploadcare::Api::File.new(api, "not-uuid")}.to raise_error
  end

  it 'has a valid url' do
    expect(file.uuid).to match UUID_REGEX
  end

  it 'returns a public url' do
    expect(file).to respond_to :cdn_url
    expect(file).to respond_to :public_url
  end

  it 'has a public url that is valid' do
    url = file.cdn_url
    uri = URI.parse(url)
    expect(uri).to be_kind_of(URI::HTTP)
  end

  it 'is able to load image data' do
    expect {file.load_data}.to_not raise_error
  end

  it 'stores itself' do
    expect { file.store }.to_not raise_error
  end

  it 'responds with nil for :stored? and :deleted? methods unless loaded' do
    expect(file.is_loaded?).to be false
    expect(file.is_stored?).to be_nil
    expect(file.is_deleted?).to be_nil
  end

  it 'is able to tell thenever file was stored' do
    file.load
    expect(file.stored?).to be(true)
    wait_until_ready(file)
    file.delete
    expect(file.stored?).to be(false)
  end

  it 'deletes itself' do
    expect { file.delete }.to_not raise_error
  end

  it 'is able to tell thenever file was deleted' do
    file.load
    file.is_deleted?.should == false
    wait_until_ready(file)
    file.delete
    expect(file.is_deleted?).to be true
  end

  it 'constructs file from uuid' do
    uuid_file = api.file file.uuid
    expect(uuid_file).to be_kind_of(Uploadcare::Api::File)
  end

  it 'constructs file from cdn url' do
    url = file.cdn_url + "-/crop/150x150/center/-/format/png/"
    file = api.file url
    expect(file).to be_kind_of(Uploadcare::Api::File)
  end

  it 'responds to datetime_ methods' do
    file.load
    expect(file).to respond_to(:datetime_original)
    expect(file).to respond_to(:datetime_uploaded)
    expect(file).to respond_to(:datetime_stored)
    expect(file).to respond_to(:datetime_removed)
  end

  it 'responds to datetime_uploaded' do
    file.load
    expect(file.datetime_uploaded).to be_kind_of(DateTime)
  end

  it 'responds to datetime_stored' do
    file.load
    file.store
    expect(file.datetime_stored).to be_kind_of(DateTime)
  end

  it 'responds to datetime_removed' do
    file.load
    wait_until_ready(file)
    file.delete
    expect(file.datetime_removed).to be_kind_of(DateTime)
    expect(file.datetime_deleted).to be_kind_of(DateTime)
    expect(file.datetime_removed).to eq file.datetime_deleted
  end


  it 'copies itself' do
    # This can cause "File is not ready yet" error if ran too early
    # In this case we retry it 3 times before giving up
    result = retry_if(Uploadcare::Error::RequestError::BadRequest){file.copy}
    expect(result).to be_kind_of(Hash)
    expect(result["type"]).to eq "file"
  end


  describe '#internal_copy' do
    describe 'integration' do
      it 'creates an internal copy of the file' do
        response = retry_if(Uploadcare::Error::RequestError::BadRequest){file.internal_copy}

        expect( response['type'] ).to eq 'file'
        expect( response['result']['uuid'] ).not_to eq file.uuid
      end
    end

    describe 'params' do
      let(:url_without_ops){ api.file(SecureRandom.uuid).cdn_url }
      let(:url_with_ops){ url_without_ops + "-/crop/5x5/center/" }
      let(:file){ api.file(url_with_ops) }

      context 'if no params given' do
        it 'requests server to create an unstored copy with operataions applied' do
          expect(api).to receive(:post)
            .with('/files/', source: url_with_ops)

          file.internal_copy
        end
      end

      context 'if strip_operations: true given' do
        it 'passes url without operations as a source for a copy' do
          expect(api).to receive(:post)
            .with('/files/', source: url_without_ops)

          file.internal_copy(strip_operations: true)
        end
      end

      context 'if store: true given' do
        it 'requests server to create a stored copy' do
          expect(api).to receive(:post)
            .with('/files/', source: url_with_ops, store: true)

          file.internal_copy(store: true)
        end
      end
    end
  end


  describe '#external_copy' do
    let(:target){ 'with-prefix' }

    describe 'integration', :payed_feature do
      it 'creates an external copy of the file' do
        response = retry_if(Uploadcare::Error::RequestError::BadRequest) do
                     file.external_copy(target)
                   end

        expect( response['type'] ).to eq 'url'
        expect( response['result'] ).to match(URI.regexp)
      end
    end

    describe 'params' do
      let(:url_without_ops){ api.file(SecureRandom.uuid).cdn_url }
      let(:url_with_ops){ url_without_ops + "-/resize/50x50/" }
      let(:file){ api.file(url_with_ops) }

      context 'if only target is given' do
        it 'requests server to create a private copy with default name and with operataions applied' do
          expect(api).to receive(:post)
            .with('/files/', source: url_with_ops, target: target)

          file.external_copy(target)
        end
      end

      context 'if target is not given' do
        it 'raises ArgumentError' do
          expect{ file.external_copy }.to raise_error(ArgumentError)
        end
      end

      context 'if strip_operations: true given' do
        it 'passes url without operations as a source for a copy' do
          expect(api).to receive(:post)
            .with('/files/', source: url_without_ops, target: target)

          file.external_copy(target, strip_operations: true)
        end
      end

      context 'if :make_public given' do
        it 'requests server to create a copy with correspondent permissions' do
          expect(api).to receive(:post)
            .with('/files/', source: url_with_ops, target: target, make_public: false)

          file.external_copy(target, make_public: false)
        end
      end

      context 'if :pattern given' do
        it 'requests server to apply given pattern to name of a copy' do
          expect(api).to receive(:post)
            .with('/files/', source: url_with_ops, target: target, pattern: 'test')

          file.external_copy(target, pattern: 'test')
        end
      end
    end
  end
end
