# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Exception::ThrottleError do
  describe 'inheritance' do
    it 'inherits from StandardError' do
      expect(described_class).to be < StandardError
    end
  end

  describe 'initialization' do
    it 'can be initialized without arguments' do
      error = described_class.new
      expect(error.timeout).to eq(10.0)
      expect(error.message).to be_a(String)
    end

    it 'can be initialized with a custom timeout' do
      error = described_class.new(30.5)
      expect(error.timeout).to eq(30.5)
    end

    it 'accepts integer timeout values' do
      error = described_class.new(60)
      expect(error.timeout).to eq(60)
    end

    it 'accepts float timeout values' do
      error = described_class.new(45.75)
      expect(error.timeout).to eq(45.75)
    end

    it 'accepts zero timeout' do
      error = described_class.new(0)
      expect(error.timeout).to eq(0)
    end

    it 'accepts very small timeout values' do
      error = described_class.new(0.1)
      expect(error.timeout).to eq(0.1)
    end
  end

  describe 'timeout attribute' do
    it 'has a readable timeout attribute' do
      error = described_class.new(25.5)
      expect(error).to respond_to(:timeout)
      expect(error.timeout).to eq(25.5)
    end

    it 'does not allow timeout modification after creation' do
      error = described_class.new(30.0)
      expect(error).not_to respond_to(:timeout=)
    end

    it 'preserves timeout precision' do
      precise_timeout = 12.345678
      error = described_class.new(precise_timeout)
      expect(error.timeout).to eq(precise_timeout)
    end
  end

  describe 'raising and catching' do
    it 'can be raised and caught with default timeout' do
      expect do
        raise described_class
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to eq(10.0)
      end
    end

    it 'can be raised and caught with custom timeout' do
      expect do
        raise described_class.new(45.0)
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to eq(45.0)
      end
    end

    it 'can be caught as StandardError' do
      expect do
        raise described_class.new(15.0)
      end.to raise_error(StandardError)
    end

    it 'can be caught as Uploadcare::Exception::ThrottleError' do
      expect do
        raise described_class.new(20.0)
      end.to raise_error(Uploadcare::Exception::ThrottleError)
    end
  end

  describe 'throttling scenarios' do
    it 'handles API rate limiting' do
      expect do
        raise described_class.new(60.0)
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to eq(60.0)
      end
    end

    it 'handles short throttle periods' do
      expect do
        raise described_class.new(1.5)
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to eq(1.5)
      end
    end

    it 'handles long throttle periods' do
      expect do
        raise described_class.new(300.0)
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to eq(300.0)
      end
    end

    it 'handles immediate retry scenarios' do
      expect do
        raise described_class.new(0.0)
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to eq(0.0)
      end
    end
  end

  describe 'upload throttling scenarios' do
    it 'handles upload rate limiting' do
      upload_throttle_time = 45.0
      expect do
        raise described_class.new(upload_throttle_time)
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to eq(upload_throttle_time)
      end
    end

    it 'handles bandwidth throttling' do
      bandwidth_throttle_time = 120.0
      expect do
        raise described_class.new(bandwidth_throttle_time)
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to eq(bandwidth_throttle_time)
      end
    end

    it 'handles concurrent upload limits' do
      concurrent_limit_throttle = 30.0
      expect do
        raise described_class.new(concurrent_limit_throttle)
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to eq(concurrent_limit_throttle)
      end
    end
  end

  describe 'API endpoint throttling' do
    it 'handles conversion API throttling' do
      conversion_throttle = 180.0
      expect do
        raise described_class.new(conversion_throttle)
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to eq(conversion_throttle)
      end
    end

    it 'handles file listing API throttling' do
      listing_throttle = 15.0
      expect do
        raise described_class.new(listing_throttle)
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to eq(listing_throttle)
      end
    end

    it 'handles metadata API throttling' do
      metadata_throttle = 5.0
      expect do
        raise described_class.new(metadata_throttle)
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to eq(metadata_throttle)
      end
    end
  end

  describe 'message handling' do
    it 'accepts custom error messages' do
      custom_message = 'Custom throttle message'
      error = described_class.new(25.0)

      expect do
        raise error, custom_message
      end.to raise_error(described_class, custom_message) do |caught_error|
        expect(caught_error.timeout).to eq(25.0)
      end
    end

    it 'preserves timeout when re-raising with message' do
      error = described_class.new(40.0)

      begin
        raise error, 'Rate limited - please wait'
      rescue described_class => e
        expect(e.timeout).to eq(40.0)
        expect(e.message).to eq('Rate limited - please wait')
      end
    end
  end

  describe 'timeout value validation scenarios' do
    context 'with negative timeout values' do
      it 'accepts negative timeout values' do
        error = described_class.new(-5.0)
        expect(error.timeout).to eq(-5.0)
      end
    end

    context 'with nil timeout values' do
      it 'accepts nil timeout values' do
        error = described_class.new(nil)
        expect(error.timeout).to be_nil
      end
    end

    context 'with string timeout values' do
      it 'accepts numeric string values' do
        error = described_class.new('25.5')
        expect(error.timeout).to eq('25.5')
      end
    end
  end

  describe 'real-world throttling patterns' do
    it 'handles exponential backoff timeouts' do
      backoff_sequence = [1, 2, 4, 8, 16, 32]

      backoff_sequence.each do |timeout|
        expect do
          raise described_class.new(timeout)
        end.to raise_error(described_class) do |error|
          expect(error.timeout).to eq(timeout)
        end
      end
    end

    it 'handles linear backoff timeouts' do
      linear_sequence = [10, 20, 30, 40, 50]

      linear_sequence.each do |timeout|
        expect do
          raise described_class.new(timeout)
        end.to raise_error(described_class) do |error|
          expect(error.timeout).to eq(timeout)
        end
      end
    end

    it 'handles jittered timeout values' do
      base_timeout = 30.0
      jitter = 5.0
      jittered_timeout = base_timeout + (((rand * 2) - 1) * jitter)

      expect do
        raise described_class.new(jittered_timeout)
      end.to raise_error(described_class) do |error|
        expect(error.timeout).to be_within(jitter).of(base_timeout)
      end
    end
  end

  describe 'error context preservation' do
    it 'maintains timeout across error handling' do
      original_timeout = 42.5

      begin
        begin
          raise described_class.new(original_timeout)
        rescue described_class => e
          raise e
        end
      rescue described_class => e
        expect(e.timeout).to eq(original_timeout)
      end
    end

    it 'preserves timeout when wrapped in other errors' do
      throttle_error = described_class.new(33.0)

      begin
        raise StandardError, "Wrapped: #{throttle_error.message}"
      rescue StandardError
        expect(throttle_error.timeout).to eq(33.0)
      end
    end
  end

  describe 'backtrace handling' do
    it 'preserves backtrace information' do
      raise described_class.new(15.0)
    rescue described_class => e
      expect(e.backtrace).to be_an(Array)
      expect(e.backtrace.first).to include(__FILE__)
      expect(e.timeout).to eq(15.0)
    end

    it 'maintains timeout and backtrace across re-raise' do
      original_timeout = 22.5
      original_backtrace = nil

      begin
        begin
          raise described_class.new(original_timeout)
        rescue described_class => e
          original_backtrace = e.backtrace
          raise e
        end
      rescue described_class => e
        expect(e.timeout).to eq(original_timeout)
        expect(e.backtrace).to eq(original_backtrace)
      end
    end
  end
end
