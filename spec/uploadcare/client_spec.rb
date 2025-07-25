# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Client do
  let(:config) { Uploadcare::Configuration.new(public_key: 'test_public', secret_key: 'test_secret') }
  let(:client) { described_class.new(config) }

  describe '#initialize' do
    context 'with Configuration object' do
      it 'uses the provided configuration' do
        expect(client.config).to eq(config)
      end
    end

    context 'with options hash' do
      let(:client) { described_class.new(public_key: 'test_public', secret_key: 'test_secret') }

      it 'creates a new configuration' do
        expect(client.config).to be_a(Uploadcare::Configuration)
        expect(client.config.public_key).to eq('test_public')
      end
    end

    it 'sets up default middleware' do
      logger = instance_double(Logger)
      config = Uploadcare::Configuration.new(
        public_key: 'test_public',
        secret_key: 'test_secret',
        max_request_tries: 3,
        logger: logger
      )
      client = described_class.new(config)

      # Should have added retry and logger middleware
      expect(client.instance_variable_get(:@middleware).size).to eq(2)
      expect(client.instance_variable_get(:@middleware).map { |m| m[:klass] }).to eq([
                                                                                       Uploadcare::Middleware::Retry,
                                                                                       Uploadcare::Middleware::Logger
                                                                                     ])
    end
  end

  describe '#use' do
    let(:test_middleware) do
      Class.new do
        def initialize(app, options = {})
          @app = app
          @options = options
        end

        def call(env)
          @app.call(env)
        end
      end
    end

    it 'adds middleware to the stack' do
      client.use(test_middleware, { option: 'value' })
      middleware = client.instance_variable_get(:@middleware)

      expect(middleware.last[:klass]).to eq(test_middleware)
      expect(middleware.last[:options]).to eq({ option: 'value' })
    end

    it 'returns self for chaining' do
      expect(client.use(test_middleware)).to eq(client)
    end
  end

  describe '#remove' do
    let(:removable_middleware) do
      Class.new do
        def initialize(app, _options = {})
          @app = app
        end

        def call(env)
          @app.call(env)
        end
      end
    end

    it 'removes middleware from the stack' do
      client.use(removable_middleware)
      expect(client.instance_variable_get(:@middleware).any? { |m| m[:klass] == removable_middleware }).to be true

      client.remove(removable_middleware)
      expect(client.instance_variable_get(:@middleware).any? { |m| m[:klass] == removable_middleware }).to be false
    end

    it 'returns self for chaining' do
      expect(client.remove(removable_middleware)).to eq(client)
    end
  end

  describe '#request' do
    it 'builds environment hash correctly' do
      allow(client).to receive(:execute_request) do |env|
        expect(env[:method]).to eq(:get)
        expect(env[:url]).to eq('https://api.uploadcare.com/test')
        expect(env[:request_headers]).to eq({ 'X-Test' => 'value' })
        expect(env[:body]).to eq({ data: 'test' })
        expect(env[:params]).to eq({ query: 'param' })
        expect(env[:config]).to eq(config)
        { status: 200, headers: {}, body: {} }
      end

      client.request(:get, 'https://api.uploadcare.com/test', {
                       headers: { 'X-Test' => 'value' },
                       body: { data: 'test' },
                       params: { query: 'param' }
                     })
    end

    it 'executes middleware stack in correct order' do
      call_order = []

      first_middleware = Class.new do
        define_method :initialize do |app, _options = {}|
          @app = app
        end

        define_method :call do |env|
          call_order << :first
          @app.call(env)
        end
      end

      second_middleware = Class.new do
        define_method :initialize do |app, _options = {}|
          @app = app
        end

        define_method :call do |env|
          call_order << :second
          @app.call(env)
        end
      end

      client.use(first_middleware)
      client.use(second_middleware)

      allow(client).to receive(:execute_request) do |_env|
        call_order << :base
        { status: 200, headers: {}, body: {} }
      end

      client.request(:get, 'https://api.uploadcare.com/test')

      expect(call_order).to eq(%i[second first base])
    end
  end

  describe 'Resource accessors' do
    describe '#files' do
      it 'returns a FileResource instance' do
        expect(client.files).to be_a(Uploadcare::Client::FileResource)
      end

      it 'memoizes the resource' do
        expect(client.files).to be(client.files)
      end
    end

    describe '#uploads' do
      it 'returns an UploadResource instance' do
        expect(client.uploads).to be_a(Uploadcare::Client::UploadResource)
      end

      it 'memoizes the resource' do
        expect(client.uploads).to be(client.uploads)
      end
    end

    describe '#groups' do
      it 'returns a GroupResource instance' do
        expect(client.groups).to be_a(Uploadcare::Client::GroupResource)
      end

      it 'memoizes the resource' do
        expect(client.groups).to be(client.groups)
      end
    end

    describe '#projects' do
      it 'returns a ProjectResource instance' do
        expect(client.projects).to be_a(Uploadcare::Client::ProjectResource)
      end

      it 'memoizes the resource' do
        expect(client.projects).to be(client.projects)
      end
    end

    describe '#webhooks' do
      it 'returns a WebhookResource instance' do
        expect(client.webhooks).to be_a(Uploadcare::Client::WebhookResource)
      end

      it 'memoizes the resource' do
        expect(client.webhooks).to be(client.webhooks)
      end
    end

    describe '#add_ons' do
      it 'returns an AddOnResource instance' do
        expect(client.add_ons).to be_a(Uploadcare::Client::AddOnResource)
      end

      it 'memoizes the resource' do
        expect(client.add_ons).to be(client.add_ons)
      end
    end
  end

  describe 'FileResource' do
    let(:file_resource) { client.files }

    describe '#list' do
      it 'delegates to Uploadcare::File.list' do
        expect(Uploadcare::File).to receive(:list).with({ limit: 10 }, config)
        file_resource.list(limit: 10)
      end
    end

    describe '#find' do
      it 'creates a File instance and calls info' do
        file = instance_double(Uploadcare::File)
        expect(Uploadcare::File).to receive(:new).with({ uuid: 'test-uuid' }, config).and_return(file)
        expect(file).to receive(:info)

        file_resource.find('test-uuid')
      end
    end

    describe '#store' do
      it 'creates a File instance and calls store' do
        file = instance_double(Uploadcare::File)
        expect(Uploadcare::File).to receive(:new).with({ uuid: 'test-uuid' }, config).and_return(file)
        expect(file).to receive(:store)

        file_resource.store('test-uuid')
      end
    end

    describe '#delete' do
      it 'creates a File instance and calls delete' do
        file = instance_double(Uploadcare::File)
        expect(Uploadcare::File).to receive(:new).with({ uuid: 'test-uuid' }, config).and_return(file)
        expect(file).to receive(:delete)

        file_resource.delete('test-uuid')
      end
    end

    describe '#batch_store' do
      it 'delegates to Uploadcare::File.batch_store' do
        uuids = %w[uuid1 uuid2]
        expect(Uploadcare::File).to receive(:batch_store).with(uuids, config)
        file_resource.batch_store(uuids)
      end
    end

    describe '#batch_delete' do
      it 'delegates to Uploadcare::File.batch_delete' do
        uuids = %w[uuid1 uuid2]
        expect(Uploadcare::File).to receive(:batch_delete).with(uuids, config)
        file_resource.batch_delete(uuids)
      end
    end

    describe '#local_copy' do
      it 'delegates to Uploadcare::File.local_copy' do
        expect(Uploadcare::File).to receive(:local_copy).with('source-uuid', { metadata: true }, config)
        file_resource.local_copy('source-uuid', metadata: true)
      end
    end

    describe '#remote_copy' do
      it 'delegates to Uploadcare::File.remote_copy' do
        expect(Uploadcare::File).to receive(:remote_copy).with('source', 'target', { make_public: true }, config)
        file_resource.remote_copy('source', 'target', make_public: true)
      end
    end
  end

  describe 'UploadResource' do
    let(:upload_resource) { client.uploads }

    describe '#upload' do
      it 'delegates to Uploadcare::Uploader.upload' do
        expect(Uploadcare::Uploader).to receive(:upload).with('input', { store: true }, config)
        upload_resource.upload('input', store: true)
      end
    end

    describe '#from_url' do
      it 'delegates to Uploadcare::Uploader.upload_from_url' do
        expect(Uploadcare::Uploader).to receive(:upload_from_url).with('http://example.com', { store: true }, config)
        upload_resource.from_url('http://example.com', store: true)
      end
    end

    describe '#from_file' do
      it 'delegates to Uploadcare::Uploader.upload_file' do
        file = double('file')
        expect(Uploadcare::Uploader).to receive(:upload_file).with(file, { store: true }, config)
        upload_resource.from_file(file, store: true)
      end
    end

    describe '#multiple' do
      it 'delegates to Uploadcare::Uploader.upload_files' do
        files = [double('file1'), double('file2')]
        expect(Uploadcare::Uploader).to receive(:upload_files).with(files, { store: true }, config)
        upload_resource.multiple(files, store: true)
      end
    end

    describe '#status' do
      it 'delegates to Uploadcare::Uploader.check_upload_status' do
        expect(Uploadcare::Uploader).to receive(:check_upload_status).with('token123', config)
        upload_resource.status('token123')
      end
    end
  end

  describe 'GroupResource' do
    let(:group_resource) { client.groups }

    describe '#list' do
      it 'delegates to Uploadcare::Group.list' do
        expect(Uploadcare::Group).to receive(:list).with({ limit: 10 }, config)
        group_resource.list(limit: 10)
      end
    end

    describe '#find' do
      it 'creates a Group instance and calls info' do
        group = instance_double(Uploadcare::Group)
        expect(Uploadcare::Group).to receive(:new).with({ id: 'test-uuid' }, config).and_return(group)
        expect(group).to receive(:info)

        group_resource.find('test-uuid')
      end
    end

    describe '#create' do
      it 'delegates to Uploadcare::Group.create' do
        files = %w[file1 file2]
        expect(Uploadcare::Group).to receive(:create).with(files, { callback: 'url' }, config)
        group_resource.create(files, callback: 'url')
      end
    end

    describe '#delete' do
      it 'creates a Group instance and calls delete' do
        group = instance_double(Uploadcare::Group)
        expect(Uploadcare::Group).to receive(:new).with({ id: 'test-uuid' }, config).and_return(group)
        expect(group).to receive(:delete).with('test-uuid')

        group_resource.delete('test-uuid')
      end
    end
  end

  describe 'ProjectResource' do
    let(:project_resource) { client.projects }

    describe '#info' do
      it 'delegates to Uploadcare::Project.info' do
        expect(Uploadcare::Project).to receive(:info).with(config)
        project_resource.info
      end
    end
  end

  describe 'WebhookResource' do
    let(:webhook_resource) { client.webhooks }

    describe '#list' do
      it 'delegates to Uploadcare::Webhook.list' do
        expect(Uploadcare::Webhook).to receive(:list).with({ limit: 10 }, config)
        webhook_resource.list(limit: 10)
      end
    end

    describe '#create' do
      it 'delegates to Uploadcare::Webhook.create' do
        expect(Uploadcare::Webhook).to receive(:create).with(
          { target_url: 'http://example.com', event: 'file.uploaded' },
          config
        )
        webhook_resource.create('http://example.com', event: 'file.uploaded')
      end
    end

    describe '#update' do
      it 'creates a Webhook instance and calls update' do
        webhook = instance_double(Uploadcare::Webhook)
        expect(Uploadcare::Webhook).to receive(:new).with({ id: 123 }, config).and_return(webhook)
        expect(webhook).to receive(:update).with({ is_active: false })

        webhook_resource.update(123, is_active: false)
      end
    end

    describe '#delete' do
      it 'delegates to Uploadcare::Webhook.delete' do
        expect(Uploadcare::Webhook).to receive(:delete).with('http://example.com', config)
        webhook_resource.delete('http://example.com')
      end
    end
  end

  describe 'AddOnResource' do
    let(:addon_resource) { client.add_ons }

    describe '#execute' do
      it 'delegates to Uploadcare::AddOns.execute' do
        expect(Uploadcare::AddOns).to receive(:execute).with('aws_rekognition', 'target-uuid', { param: 'value' }, config)
        addon_resource.execute('aws_rekognition', 'target-uuid', param: 'value')
      end
    end

    describe '#status' do
      it 'delegates to Uploadcare::AddOns.status' do
        expect(Uploadcare::AddOns).to receive(:status).with('aws_rekognition', 'request-id', config)
        addon_resource.status('aws_rekognition', 'request-id')
      end
    end
  end
end
