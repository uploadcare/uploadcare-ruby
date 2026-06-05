# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api::Rest do
  subject(:rest) { described_class.new(config: config) }

  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end

  describe '#initialize' do
    it 'stores the config' do
      expect(rest.config).to eq(config)
    end

    it 'creates a Faraday connection to the REST API root' do
      expect(rest.connection).to be_a(Faraday::Connection)
      expect(rest.connection.url_prefix.to_s).to eq('https://api.uploadcare.com/')
    end

    it 'creates an authenticator' do
      expect(rest.authenticator).to be_a(Uploadcare::Internal::Authenticator)
    end

    it 'defaults to global configuration when no config is provided' do
      Uploadcare.configure do |c|
        c.public_key = 'globalpubkey'
        c.secret_key = 'globalseckey'
        c.auth_type = 'Uploadcare.Simple'
      end

      default_rest = described_class.new
      expect(default_rest.config.public_key).to eq('globalpubkey')
    end
  end

  describe 'User-Agent header' do
    it 'sends the SDK User-Agent on REST API requests, not the Faraday default' do
      expected_user_agent = Uploadcare::Internal::UserAgent.call(config: config)
      stub_request(:get, 'https://api.uploadcare.com/files/')
        .with(headers: { 'User-Agent' => expected_user_agent })
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      rest.get(path: '/files/', params: {}, headers: {}, request_options: {})

      expect(
        a_request(:get, 'https://api.uploadcare.com/files/')
          .with(headers: { 'User-Agent' => %r{\AUploadcareRuby/} })
      ).to have_been_made
    end
  end

  describe '#get' do
    it 'returns a successful Result on 200' do
      stub_request(:get, 'https://api.uploadcare.com/files/')
        .to_return(
          status: 200,
          body: { results: [], next: nil }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = rest.get(path: '/files/', params: {}, headers: {}, request_options: {})

      expect(result).to be_a(Uploadcare::Result)
      expect(result).to be_success
      expect(result.value!).to eq({ 'results' => [], 'next' => nil })
    end

    it 'returns a failure Result on API error' do
      stub_request(:get, 'https://api.uploadcare.com/files/')
        .to_return(
          status: 404,
          body: { detail: 'Not found.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = rest.get(path: '/files/', params: {}, headers: {}, request_options: {})

      expect(result).to be_failure
      expect(result.error).to be_a(Uploadcare::Exception::NotFoundError)
    end

    it 'passes query params for GET requests' do
      stub_request(:get, 'https://api.uploadcare.com/files/')
        .with(query: { limit: '10', ordering: '-datetime_uploaded' })
        .to_return(
          status: 200,
          body: { results: [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = rest.get(
        path: '/files/',
        params: { limit: '10', ordering: '-datetime_uploaded' },
        headers: {},
        request_options: {}
      )

      expect(result).to be_success
    end

    it 'signs GET URI with the same nested params encoding used by Faraday' do
      authenticator = instance_double(Uploadcare::Internal::Authenticator)
      allow(authenticator).to receive(:default_headers).and_return(
        {
          'Accept' => 'application/vnd.uploadcare-v0.7+json',
          'Content-Type' => 'application/json'
        }
      )
      allow(authenticator).to receive(:headers)
        .with('GET', '/files/?tags%5B%5D=a&tags%5B%5D=b', '', 'application/json')
        .and_return(
          {
            'Accept' => 'application/vnd.uploadcare-v0.7+json',
            'Authorization' => 'Uploadcare.Simple demopublickey:demosecretkey',
            'Content-Type' => 'application/json'
          }
        )
      rest.instance_variable_set(:@authenticator, authenticator)

      stub_request(:get, %r{\Ahttps://api\.uploadcare\.com/files/\?tags%5B%5D=a&tags%5B%5D=b\z})
        .to_return(
          status: 200,
          body: { results: [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = rest.get(path: '/files/', params: { tags: %w[a b] }, headers: {}, request_options: {})

      expect(result).to be_success
    end
  end

  describe '#post' do
    it 'returns a successful Result on 200' do
      stub_request(:post, 'https://api.uploadcare.com/files/local_copy/')
        .to_return(
          status: 200,
          body: { type: 'file', result: { uuid: 'new-uuid' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = rest.post(
        path: '/files/local_copy/',
        params: { source: 'some-uuid' },
        headers: {},
        request_options: {}
      )

      expect(result).to be_success
      expect(result.value!['type']).to eq('file')
    end

    it 'returns a failure Result on 400' do
      stub_request(:post, 'https://api.uploadcare.com/files/local_copy/')
        .to_return(
          status: 400,
          body: { detail: 'Invalid source.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = rest.post(
        path: '/files/local_copy/',
        params: { source: '' },
        headers: {},
        request_options: {}
      )

      expect(result).to be_failure
      expect(result.error).to be_a(Uploadcare::Exception::InvalidRequestError)
    end

    it 'uses the resolved Content-Type consistently for signing and request headers' do
      authenticator = instance_double(Uploadcare::Internal::Authenticator)
      allow(authenticator).to receive(:default_headers).and_return(
        { 'Accept' => 'application/vnd.uploadcare-v0.7+json', 'Content-Type' => 'application/json' }
      )
      allow(authenticator).to receive(:headers)
        .with('POST', '/files/local_copy/', 'plain body', 'text/plain')
        .and_return(
          {
            'Accept' => 'application/vnd.uploadcare-v0.7+json',
            'Authorization' => 'Uploadcare.Simple demopublickey:demosecretkey',
            'Content-Type' => 'text/plain'
          }
        )

      rest.instance_variable_set(:@authenticator, authenticator)

      stub = stub_request(:post, 'https://api.uploadcare.com/files/local_copy/')
             .with(body: 'plain body', headers: { 'Content-Type' => 'text/plain' })
             .to_return(
               status: 200,
               body: { type: 'file', result: { uuid: 'new-uuid' } }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      result = rest.post(
        path: '/files/local_copy/',
        params: 'plain body',
        headers: { 'content-type' => 'text/plain' },
        request_options: {}
      )

      expect(result).to be_success
      expect(stub).to have_been_requested
    end
  end

  describe '#put' do
    it 'returns a successful Result on 200' do
      stub_request(:put, 'https://api.uploadcare.com/files/test-uuid/storage/')
        .to_return(
          status: 200,
          body: { uuid: 'test-uuid', is_stored: true }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = rest.put(
        path: '/files/test-uuid/storage/',
        params: {},
        headers: {},
        request_options: {}
      )

      expect(result).to be_success
      expect(result.value!['is_stored']).to be true
    end
  end

  describe '#delete' do
    it 'returns a successful Result on 200' do
      stub_request(:delete, 'https://api.uploadcare.com/files/test-uuid/storage/')
        .to_return(
          status: 200,
          body: { uuid: 'test-uuid' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = rest.delete(
        path: '/files/test-uuid/storage/',
        params: {},
        headers: {},
        request_options: {}
      )

      expect(result).to be_success
    end
  end

  describe '#make_request' do
    it 'returns the parsed response body directly' do
      stub_request(:get, 'https://api.uploadcare.com/project/')
        .to_return(
          status: 200,
          body: { name: 'Test Project' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      body = rest.make_request(method: :get, path: '/project/', params: {}, headers: {}, request_options: {})

      expect(body).to eq({ 'name' => 'Test Project' })
    end

    it 'raises an error on failure instead of returning a Result' do
      stub_request(:get, 'https://api.uploadcare.com/project/')
        .to_return(
          status: 404,
          body: { detail: 'Not found.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        rest.make_request(method: :get, path: '/project/', params: {}, headers: {}, request_options: {})
      end.to raise_error(Uploadcare::Exception::NotFoundError)
    end
  end

  describe '#request' do
    it 'wraps make_request in a Result' do
      stub_request(:delete, 'https://api.uploadcare.com/files/test-uuid/storage/')
        .to_return(
          status: 200,
          body: { uuid: 'test-uuid' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = rest.request(
        method: :delete,
        path: '/files/test-uuid/storage/',
        params: {},
        headers: {},
        request_options: {}
      )

      expect(result).to be_a(Uploadcare::Result)
      expect(result).to be_success
    end
  end

  describe 'endpoint accessors' do
    it 'returns a Files endpoint' do
      expect(rest.files).to be_a(Uploadcare::Api::Rest::Files)
    end

    it 'returns a Groups endpoint' do
      expect(rest.groups).to be_a(Uploadcare::Api::Rest::Groups)
    end

    it 'returns a Project endpoint' do
      expect(rest.project).to be_a(Uploadcare::Api::Rest::Project)
    end

    it 'returns a Webhooks endpoint' do
      expect(rest.webhooks).to be_a(Uploadcare::Api::Rest::Webhooks)
    end

    it 'returns a FileMetadata endpoint' do
      expect(rest.file_metadata).to be_a(Uploadcare::Api::Rest::FileMetadata)
    end

    it 'returns an Addons endpoint' do
      expect(rest.addons).to be_a(Uploadcare::Api::Rest::Addons)
    end

    it 'returns a DocumentConversions endpoint' do
      expect(rest.document_conversions).to be_a(Uploadcare::Api::Rest::DocumentConversions)
    end

    it 'returns a VideoConversions endpoint' do
      expect(rest.video_conversions).to be_a(Uploadcare::Api::Rest::VideoConversions)
    end

    it 'memoizes endpoint instances' do
      files = rest.files
      groups = rest.groups
      project = rest.project
      webhooks = rest.webhooks
      file_metadata = rest.file_metadata
      addons = rest.addons
      document_conversions = rest.document_conversions
      video_conversions = rest.video_conversions

      expect(rest.files).to be(files)
      expect(rest.groups).to be(groups)
      expect(rest.project).to be(project)
      expect(rest.webhooks).to be(webhooks)
      expect(rest.file_metadata).to be(file_metadata)
      expect(rest.addons).to be(addons)
      expect(rest.document_conversions).to be(document_conversions)
      expect(rest.video_conversions).to be(video_conversions)
    end
  end

  describe 'request options' do
    it 'applies timeout from request_options' do
      stub_request(:get, 'https://api.uploadcare.com/files/')
        .to_return(
          status: 200,
          body: { results: [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = rest.get(
        path: '/files/',
        params: {},
        headers: {},
        request_options: { timeout: 30, open_timeout: 10 }
      )

      expect(result).to be_success
    end
  end

  describe 'authentication headers' do
    it 'includes authorization headers in requests' do
      stub_request(:get, 'https://api.uploadcare.com/project/')
        .with(headers: { 'Authorization' => /Uploadcare.Simple demopublickey:demosecretkey/ })
        .to_return(
          status: 200,
          body: { name: 'Demo' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = rest.get(path: '/project/', params: {}, headers: {}, request_options: {})

      expect(result).to be_success
    end
  end
end
