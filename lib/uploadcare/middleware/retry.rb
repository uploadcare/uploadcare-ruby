# frozen_string_literal: true

require_relative 'base'

module Uploadcare
  module Middleware
    class Retry < Base
      DEFAULT_RETRY_OPTIONS = {
        max_retries: 3,
        retry_statuses: [429, 502, 503, 504],
        exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed],
        methods: %i[get head options],
        retry_if: nil,
        backoff_factor: 2,
        exceptions_to_retry: []
      }.freeze

      def initialize(app, options = {})
        super(app)
        @options = DEFAULT_RETRY_OPTIONS.merge(options)
        @logger = @options[:logger]
      end

      def call(env)
        retries = 0
        begin
          response = @app.call(env)

          if should_retry?(env, response, nil, retries)
            retries += 1
            log_retry(env, response[:status], retries, "status code #{response[:status]}")
            sleep(calculate_delay(retries, response))
            retry
          end

          response
        rescue StandardError => error
          if should_retry?(env, nil, error, retries)
            retries += 1
            log_retry(env, nil, retries, error.class.name)
            sleep(calculate_delay(retries))
            retry
          end
          raise
        end
      end

      private

      def should_retry?(env, response, error, retries)
        return false if retries >= @options[:max_retries]
        return false unless retryable_method?(env[:method])

        if error
          retryable_error?(error)
        elsif response
          retryable_status?(response[:status]) || custom_retry_logic?(env, response)
        else
          false
        end
      end

      def retryable_method?(method)
        @options[:methods].include?(method.to_s.downcase.to_sym)
      end

      def retryable_status?(status)
        @options[:retry_statuses].include?(status)
      end

      def retryable_error?(error)
        @options[:exceptions].any? { |klass| error.is_a?(klass) } ||
          @options[:exceptions_to_retry].any? { |klass| error.is_a?(klass) }
      end

      def custom_retry_logic?(env, response)
        return false unless @options[:retry_if]
        @options[:retry_if].call(env, response)
      end

      def calculate_delay(retries, response = nil)
        delay = @options[:backoff_factor] ** (retries - 1)

        # Check for Retry-After header
        if response && response[:headers] && response[:headers]['retry-after']
          retry_after = response[:headers]['retry-after'].to_i
          delay = retry_after if retry_after > 0
        end

        # Add jitter to prevent thundering herd
        delay + (rand * 0.3 * delay)
      end

      def log_retry(env, status, retries, reason)
        return unless @logger

        message = "[Uploadcare] Retrying #{env[:method].upcase} #{env[:url]}"
        message += " (attempt #{retries}/#{@options[:max_retries]})"
        message += " after #{reason}"

        @logger.warn(message)
      end
    end
  end
end
