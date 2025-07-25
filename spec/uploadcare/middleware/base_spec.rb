# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Middleware::Base do
  let(:app) { double('app') }
  let(:middleware) { described_class.new(app) }
  let(:env) { { method: :get, url: 'https://api.uploadcare.com/test' } }

  describe '#initialize' do
    it 'stores the app' do
      expect(middleware.instance_variable_get(:@app)).to eq(app)
    end
  end

  describe '#call' do
    it 'passes environment to the app' do
      expect(app).to receive(:call).with(env)
      middleware.call(env)
    end

    it 'returns app response' do
      response = { status: 200, body: 'OK' }
      allow(app).to receive(:call).and_return(response)

      expect(middleware.call(env)).to eq(response)
    end

    it 'does not modify the environment' do
      original_env = env.dup
      allow(app).to receive(:call)

      middleware.call(env)
      expect(env).to eq(original_env)
    end
  end

  describe 'inheritance' do
    let(:custom_middleware_class) do
      Class.new(described_class) do
        def call(env)
          env[:custom] = true
          super
        end
      end
    end

    let(:custom_middleware) { custom_middleware_class.new(app) }

    it 'allows subclasses to extend behavior' do
      expect(app).to receive(:call) do |env|
        expect(env[:custom]).to be true
      end

      custom_middleware.call(env)
    end
  end

  describe 'middleware chaining' do
    let(:app) { ->(env) { { status: 200, body: env[:data] } } }

    let(:first_middleware_class) do
      Class.new(described_class) do
        def call(env)
          env[:data] ||= []
          env[:data] << 'first'
          super
        end
      end
    end

    let(:second_middleware_class) do
      Class.new(described_class) do
        def call(env)
          env[:data] ||= []
          env[:data] << 'second'
          super
        end
      end
    end

    it 'allows multiple middleware to be chained' do
      stack = first_middleware_class.new(
        second_middleware_class.new(app)
      )

      result = stack.call({})
      expect(result[:body]).to eq(%w[first second])
    end
  end

  describe 'error handling' do
    context 'when app raises an error' do
      before do
        allow(app).to receive(:call).and_raise(StandardError, 'App error')
      end

      it 'does not catch the error' do
        expect { middleware.call(env) }.to raise_error(StandardError, 'App error')
      end
    end
  end

  describe 'thread safety' do
    it 'can be used concurrently' do
      call_count = 0
      mutex = Mutex.new

      allow(app).to receive(:call) do |_env|
        sleep(0.01) # Simulate some work
        mutex.synchronize { call_count += 1 }
        { status: 200 }
      end

      threads = 5.times.map do |i|
        Thread.new do
          middleware.call({ id: i })
        end
      end

      threads.each(&:join)
      expect(call_count).to eq(5)
    end
  end
end
