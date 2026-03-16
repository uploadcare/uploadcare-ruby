# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Coverage: edge cases and error paths' do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }

  describe 'Api::Rest error paths' do
    let(:rest) { Uploadcare::Api::Rest.new(config: config) }

    it 'handles Faraday errors in make_request' do
      stub_request(:get, 'https://api.uploadcare.com/files/')
        .to_return(status: 500, body: '{"detail":"Server Error"}', headers: { 'Content-Type' => 'application/json' })

      expect { rest.make_request(method: :get, path: '/files/', params: {}, headers: {}) }
        .to raise_error(Uploadcare::Exception::RequestError)
    end

    it 'wraps request in Result on failure' do
      stub_request(:get, 'https://api.uploadcare.com/test/')
        .to_return(status: 404, body: '{"detail":"Not found"}', headers: { 'Content-Type' => 'application/json' })

      result = rest.get(path: '/test/', params: {}, headers: {})
      expect(result.failure?).to be(true)
    end

    it 'handles request_options timeout' do
      stub_request(:get, 'https://api.uploadcare.com/files/')
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      result = rest.get(path: '/files/', params: {}, headers: {}, request_options: { timeout: 30, open_timeout: 5 })
      expect(result.success?).to be(true)
    end

    it 'builds URI with query params for GET requests' do
      stub_request(:get, %r{api\.uploadcare\.com/files/})
        .to_return(status: 200, body: '{"results":[]}', headers: { 'Content-Type' => 'application/json' })

      result = rest.get(path: '/files/', params: { limit: 10 }, headers: {})
      expect(result.success?).to be(true)
    end

    it 'handles DELETE with params as body' do
      stub_request(:delete, 'https://api.uploadcare.com/files/storage/')
        .to_return(status: 200, body: '{"result":[]}', headers: { 'Content-Type' => 'application/json' })

      result = rest.delete(path: '/files/storage/', params: ['uuid-1'], headers: {})
      expect(result.success?).to be(true)
    end

    it 'handles string body content for signature' do
      stub_request(:put, /api\.uploadcare\.com/)
        .to_return(status: 200, body: '"value"', headers: { 'Content-Type' => 'application/json' })

      result = rest.put(path: '/files/uuid/metadata/key/', params: '"value"', headers: {})
      expect(result.success?).to be(true)
    end
  end

  describe 'Api::Upload error paths' do
    let(:upload) { Uploadcare::Api::Upload.new(config: config) }

    it 'handles upload API errors' do
      stub_request(:post, 'https://upload.uploadcare.com/base/')
        .to_return(status: 500, body: 'Server Error')

      result = upload.post(path: 'base/', params: {})
      expect(result.failure?).to be(true)
    end

    it 'handles empty response bodies' do
      stub_request(:post, 'https://upload.uploadcare.com/test/')
        .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })

      result = upload.post(path: 'test/', params: {})
      expect(result.success?).to be(true)
    end

    it 'handles JSON parse errors gracefully' do
      stub_request(:post, 'https://upload.uploadcare.com/test/')
        .to_return(status: 200, body: 'not json', headers: { 'Content-Type' => 'text/plain' })

      result = upload.post(path: 'test/', params: {})
      expect(result.success?).to be(true)
    end
  end

  describe 'Api::Upload::Files edge cases' do
    let(:upload) { Uploadcare::Api::Upload.new(config: config) }
    let(:files_endpoint) { upload.files }

    it 'validates empty URL in from_url' do
      result = files_endpoint.from_url(source_url: '')
      expect(result.failure?).to be(true)
    end

    it 'validates invalid URL scheme in from_url' do
      result = files_endpoint.from_url(source_url: 'ftp://example.com/file')
      expect(result.failure?).to be(true)
    end

    it 'validates empty filename in multipart_start' do
      result = files_endpoint.multipart_start(filename: '', size: 100, content_type: 'image/jpeg')
      expect(result.failure?).to be(true)
    end

    it 'validates invalid size in multipart_start' do
      result = files_endpoint.multipart_start(filename: 'test.jpg', size: -1, content_type: 'image/jpeg')
      expect(result.failure?).to be(true)
    end

    it 'validates empty content_type in multipart_start' do
      result = files_endpoint.multipart_start(filename: 'test.jpg', size: 100, content_type: '')
      expect(result.failure?).to be(true)
    end

    it 'validates empty uuid in multipart_complete' do
      result = files_endpoint.multipart_complete(uuid: '')
      expect(result.failure?).to be(true)
    end

    it 'validates empty token in from_url_status' do
      result = files_endpoint.from_url_status(token: '')
      expect(result.failure?).to be(true)
    end

    it 'validates empty file_id in info' do
      result = files_endpoint.info(file_id: '')
      expect(result.failure?).to be(true)
    end

    it 'validates non-IO object in direct upload' do
      result = files_endpoint.direct(file: 'not_a_file')
      expect(result.failure?).to be(true)
    end
  end

  describe 'Api::Upload::Groups edge cases' do
    let(:upload) { Uploadcare::Api::Upload.new(config: config) }
    let(:groups_endpoint) { upload.groups }

    it 'validates non-array files' do
      result = groups_endpoint.create(files: 'not_array')
      expect(result.failure?).to be(true)
    end

    it 'validates empty files array' do
      result = groups_endpoint.create(files: [])
      expect(result.failure?).to be(true)
    end

    it 'validates empty group_id in info' do
      result = groups_endpoint.info(group_id: '')
      expect(result.failure?).to be(true)
    end
  end

  describe 'Operations::MultipartUpload edge cases' do
    let(:upload_client) { instance_double(Uploadcare::Api::Upload) }
    let(:mp) { Uploadcare::Operations::MultipartUpload.new(upload_client: upload_client, config: config) }

    it 'validates non-IO file objects' do
      result = mp.upload(file: 'not_a_file')
      expect(result.failure?).to be(true)
    end
  end

  describe 'Operations::UploadRouter edge cases' do
    let(:router) { Uploadcare::Operations::UploadRouter.new(client: client) }

    it 'raises ArgumentError for invalid source types' do
      expect { router.upload(12_345) }.to raise_error(ArgumentError, /Expected input/)
    end
  end

  describe 'Resources::File edge cases' do
    it 'extracts uuid from URL' do
      file = Uploadcare::Resources::File.new(
        { 'original_file_url' => 'https://ucarecdn.com/a1b2c3d4-e5f6-7890-abcd-ef1234567890/' },
        client
      )
      expect(file.uuid).to eq('a1b2c3d4-e5f6-7890-abcd-ef1234567890')
    end

    it 'returns cdn_url from url attribute' do
      file = Uploadcare::Resources::File.new(
        { 'url' => 'https://ucarecdn.com/test-uuid/' },
        client
      )
      expect(file.cdn_url).to eq('https://ucarecdn.com/test-uuid/')
    end

    it 'builds cdn_url from uuid and config' do
      file = Uploadcare::Resources::File.new({ 'uuid' => 'test-uuid-1234' }, client)
      expect(file.cdn_url).to include('test-uuid-1234')
    end
  end

  describe 'Resources::Group edge cases' do
    it 'extracts id from cdn_url' do
      group = Uploadcare::Resources::Group.new(
        { 'cdn_url' => 'https://ucarecdn.com/group-id~3/' },
        client
      )
      expect(group.id).to eq('group-id~3')
    end

    it 'returns empty file_cdn_urls when files_count is nil' do
      group = Uploadcare::Resources::Group.new({}, client)
      expect(group.file_cdn_urls).to eq([])
    end
  end

  describe 'Collections::Paginated edge cases' do
    it 'handles empty resources' do
      collection = Uploadcare::Collections::Paginated.new(resources: [])
      expect(collection.count).to eq(0)
      expect(collection.all).to eq([])
    end

    it 'returns nil for next_page when no URL' do
      collection = Uploadcare::Collections::Paginated.new(resources: [], next_page: nil)
      expect(collection.next_page).to be_nil
    end

    it 'returns nil for previous_page when no URL' do
      collection = Uploadcare::Collections::Paginated.new(resources: [], previous_page: nil)
      expect(collection.previous_page).to be_nil
    end
  end

  describe 'Collections::BatchResult' do
    it 'handles nil result array' do
      result = Uploadcare::Collections::BatchResult.new(status: 200, result: nil, problems: {}, client: client)
      expect(result.result).to eq([])
    end

    it 'handles nil problems' do
      result = Uploadcare::Collections::BatchResult.new(status: 200, result: [], problems: nil, client: client)
      expect(result.problems).to eq({})
    end
  end

  describe 'Internal::ErrorHandler edge cases' do
    let(:handler) { Class.new { include Uploadcare::Internal::ErrorHandler }.new }

    it 'handles error with nil response' do
      error = Faraday::Error.new('connection refused')
      expect { handler.handle_error(error) }.to raise_error(Uploadcare::Exception::RequestError)
    end

    it 'handles 400 status' do
      error = Faraday::ClientError.new(nil, { status: 400, body: '{"detail":"Bad request"}' })
      expect { handler.handle_error(error) }.to raise_error(Uploadcare::Exception::InvalidRequestError)
    end

    it 'handles 404 status' do
      error = Faraday::ResourceNotFound.new(nil, { status: 404, body: '{"detail":"Not found"}' })
      expect { handler.handle_error(error) }.to raise_error(Uploadcare::Exception::NotFoundError)
    end

    it 'handles 429 status with retry-after header' do
      error = Faraday::ClientError.new(nil, { status: 429, body: '{"detail":"Too many requests"}',
                                              headers: { 'retry-after' => '5' } })
      expect { handler.handle_error(error) }.to raise_error(Uploadcare::Exception::ThrottleError)
    end

    it 'handles upload API error (200 with error body)' do
      error = Faraday::ClientError.new(nil, { status: 200, body: '{"error":"Upload failed"}' })
      expect { handler.handle_error(error) }.to raise_error(Uploadcare::Exception::RequestError, 'Upload failed')
    end

    it 'handles non-JSON error body' do
      error = Faraday::ClientError.new(nil, { status: 500, body: 'Internal Server Error' })
      expect { handler.handle_error(error) }.to raise_error(Uploadcare::Exception::RequestError)
    end
  end

  describe 'Internal::ThrottleHandler edge cases' do
    let(:handler_class) do
      Class.new do
        include Uploadcare::Internal::ThrottleHandler
        def config
          Uploadcare::Configuration.new(max_throttle_attempts: 2)
        end
      end
    end
    let(:handler) { handler_class.new }

    it 'uses config max_throttle_attempts when not specified' do
      call_count = 0
      expect do
        handler.handle_throttling do
          call_count += 1
          raise Uploadcare::Exception::ThrottleError.new(timeout: 0.001) if call_count < 2

          'success'
        end
      end.not_to raise_error
    end
  end

  describe 'Result edge cases' do
    it 'raises string errors' do
      result = Uploadcare::Result.failure('string error')
      expect { result.value! }.to raise_error(RuntimeError, 'string error')
    end

    it 'captures successful blocks' do
      result = Uploadcare::Result.capture { 42 }
      expect(result.success?).to be(true)
      expect(result.value!).to eq(42)
    end
  end

  describe 'Configuration edge cases' do
    it 'reads from environment variables' do
      config = Uploadcare::Configuration.new
      expect(config.public_key).to be_a(String)
    end

    it 'supports with for creating copies' do
      original = Uploadcare::Configuration.new(public_key: 'original')
      copy = original.with(public_key: 'modified')
      expect(copy.public_key).to eq('modified')
      expect(original.public_key).to eq('original')
    end

    it 'exposes to_h' do
      config = Uploadcare::Configuration.new(public_key: 'test')
      h = config.to_h
      expect(h).to be_a(Hash)
      expect(h[:public_key]).to eq('test')
    end
  end

  describe 'Client edge cases' do
    it 'creates client with keyword options' do
      c = Uploadcare::Client.new(public_key: 'test', secret_key: 'secret')
      expect(c.config.public_key).to eq('test')
    end

    it 'creates client with config object' do
      c = Uploadcare::Client.new(config: config)
      expect(c.config).not_to equal(config)
      expect(c.config.to_h).to eq(config.to_h)
    end

    it 'creates new client via with' do
      c1 = Uploadcare::Client.new(config: config)
      c2 = c1.with(public_key: 'new_key')
      expect(c2.config.public_key).to eq('new_key')
      expect(c1.config.public_key).to eq('demopublickey')
    end

    it 'exposes all domain accessors' do
      expect(client.files).to be_a(Uploadcare::Client::FilesAccessor)
      expect(client.groups).to be_a(Uploadcare::Client::GroupsAccessor)
      expect(client.uploads).to be_a(Uploadcare::Operations::UploadRouter)
      expect(client.project).to be_a(Uploadcare::Client::ProjectAccessor)
      expect(client.webhooks).to be_a(Uploadcare::Client::WebhooksAccessor)
      expect(client.addons).to be_a(Uploadcare::Client::AddonsAccessor)
      expect(client.file_metadata).to be_a(Uploadcare::Client::FileMetadataAccessor)
      expect(client.conversions).to be_a(Uploadcare::Client::ConversionsAccessor)
      expect(client.conversions.documents).to be_a(Uploadcare::Client::DocumentConversionsAccessor)
      expect(client.conversions.videos).to be_a(Uploadcare::Client::VideoConversionsAccessor)
    end

    it 'exposes raw API access' do
      expect(client.api).to be_a(Uploadcare::Client::Api)
      expect(client.api.rest).to be_a(Uploadcare::Api::Rest)
      expect(client.api.upload).to be_a(Uploadcare::Api::Upload)
    end
  end
end
