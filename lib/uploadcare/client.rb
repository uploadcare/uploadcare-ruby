# frozen_string_literal: true

module Uploadcare
  class Client
    attr_reader :config

    def initialize(options = {})
      @config = if options.is_a?(Configuration)
                  options
                else
                  Configuration.new(options)
                end
      @middleware = []
      setup_default_middleware
    end

    # Resource accessors
    def files
      @files ||= FileResource.new(self)
    end

    def uploads
      @uploads ||= UploadResource.new(self)
    end

    def groups
      @groups ||= GroupResource.new(self)
    end

    def projects
      @projects ||= ProjectResource.new(self)
    end

    def webhooks
      @webhooks ||= WebhookResource.new(self)
    end

    def add_ons
      @add_ons ||= AddOnResource.new(self)
    end

    # Add middleware
    def use(middleware, options = {})
      @middleware << { klass: middleware, options: options }
      self
    end

    # Remove middleware
    def remove(middleware_class)
      @middleware.reject! { |m| m[:klass] == middleware_class }
      self
    end

    # Execute request with middleware stack
    def request(method, url, options = {})
      env = build_env(method, url, options)

      # Build middleware stack
      stack = @middleware.reduce(base_app) do |app, middleware|
        middleware[:klass].new(app, middleware[:options])
      end

      stack.call(env)
    end

    private

    def setup_default_middleware
      use(Middleware::Retry) if config.max_request_tries > 1
      use(Middleware::Logger, config.logger) if config.logger
    end

    def build_env(method, url, options)
      {
        method: method,
        url: url,
        request_headers: options[:headers] || {},
        body: options[:body],
        params: options[:params],
        config: config
      }
    end

    def base_app
      ->(env) { execute_request(env) }
    end

    def execute_request(_env)
      # Actual HTTP request execution
      # This would be implemented based on the specific HTTP library used
      # For now, returning a mock response structure
      {
        status: 200,
        headers: {},
        body: {}
      }
    end

    # Resource wrapper classes
    class FileResource
      def initialize(client)
        @client = client
      end

      def list(options = {})
        Uploadcare::File.list(options, @client.config)
      end

      def find(uuid)
        Uploadcare::File.new({ uuid: uuid }, @client.config).info
      end

      def store(uuid)
        Uploadcare::File.new({ uuid: uuid }, @client.config).store
      end

      def delete(uuid)
        Uploadcare::File.new({ uuid: uuid }, @client.config).delete
      end

      def batch_store(uuids)
        Uploadcare::File.batch_store(uuids, @client.config)
      end

      def batch_delete(uuids)
        Uploadcare::File.batch_delete(uuids, @client.config)
      end

      def local_copy(source, options = {})
        Uploadcare::File.local_copy(source, options, @client.config)
      end

      def remote_copy(source, target, options = {})
        Uploadcare::File.remote_copy(source, target, options, @client.config)
      end
    end

    class UploadResource
      def initialize(client)
        @client = client
      end

      def upload(input, options = {})
        Uploadcare::Uploader.upload(input, options, @client.config)
      end

      def from_url(url, options = {})
        Uploadcare::Uploader.upload_from_url(url, options, @client.config)
      end

      def from_file(file, options = {})
        Uploadcare::Uploader.upload_file(file, options, @client.config)
      end

      def multiple(files, options = {})
        Uploadcare::Uploader.upload_files(files, options, @client.config)
      end

      def status(token)
        Uploadcare::Uploader.check_upload_status(token, @client.config)
      end
    end

    class GroupResource
      def initialize(client)
        @client = client
      end

      def list(options = {})
        Uploadcare::Group.list(options, @client.config)
      end

      def find(uuid)
        Uploadcare::Group.new({ id: uuid }, @client.config).info(uuid)
      end

      def create(files, options = {})
        Uploadcare::Group.create(files, options, @client.config)
      end

      def delete(uuid)
        Uploadcare::Group.new({ id: uuid }, @client.config).delete(uuid)
      end
    end

    class ProjectResource
      def initialize(client)
        @client = client
      end

      def info
        Uploadcare::Project.info(@client.config)
      end
    end

    class WebhookResource
      def initialize(client)
        @client = client
      end

      def list(options = {})
        Uploadcare::Webhook.list(options, @client.config)
      end

      def create(target_url, options = {})
        Uploadcare::Webhook.create({ target_url: target_url }.merge(options), @client.config)
      end

      def update(id, options = {})
        webhook = Uploadcare::Webhook.new({ id: id }, @client.config)
        webhook.update(options)
      end

      def delete(target_url)
        Uploadcare::Webhook.delete(target_url, @client.config)
      end
    end

    class AddOnResource
      def initialize(client)
        @client = client
      end

      def execute(addon_name, target, options = {})
        Uploadcare::AddOns.execute(addon_name, target, options, @client.config)
      end

      def status(addon_name, request_id)
        Uploadcare::AddOns.status(addon_name, request_id, @client.config)
      end
    end
  end
end
