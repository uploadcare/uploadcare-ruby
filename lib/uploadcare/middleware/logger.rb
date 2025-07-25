# frozen_string_literal: true

require 'logger'

module Uploadcare
  module Middleware
    class Logger < Base
      def initialize(app, logger = nil)
        super(app)
        @logger = logger || ::Logger.new($stdout)
      end

      def call(env)
        started_at = Time.now
        log_request(env)
        
        response = @app.call(env)
        
        duration = Time.now - started_at
        log_response(env, response, duration)
        
        response
      rescue => e
        duration = Time.now - started_at
        log_error(env, e, duration)
        raise
      end

      private

      def log_request(env)
        @logger.info "[Uploadcare] Request: #{env[:method].upcase} #{env[:url]}"
        @logger.debug "[Uploadcare] Headers: #{filter_headers(env[:request_headers])}" if env[:request_headers]
        @logger.debug "[Uploadcare] Body: #{filter_body(env[:body])}" if env[:body]
      end

      def log_response(env, response, duration)
        @logger.info "[Uploadcare] Response: #{response[:status]} (#{format_duration(duration)})"
        @logger.debug "[Uploadcare] Response Headers: #{response[:headers]}" if response[:headers]
        @logger.debug "[Uploadcare] Response Body: #{truncate(response[:body].to_s)}" if response[:body]
      end

      def log_error(env, error, duration)
        @logger.error "[Uploadcare] Error: #{error.class} - #{error.message} (#{format_duration(duration)})"
        @logger.error "[Uploadcare] Backtrace: #{error.backtrace.first(5).join("\n")}"
      end

      def filter_headers(headers)
        headers.transform_keys(&:downcase).tap do |h|
          h['authorization'] = '[FILTERED]' if h['authorization']
          h['x-uc-auth-key'] = '[FILTERED]' if h['x-uc-auth-key']
        end
      end

      def filter_body(body)
        return body unless body.is_a?(Hash)
        
        body.dup.tap do |b|
          b['secret_key'] = '[FILTERED]' if b['secret_key']
          b['pub_key'] = '[FILTERED]' if b['pub_key']
        end
      end

      def truncate(string, length = 1000)
        return string if string.length <= length
        "#{string[0...length]}... (truncated)"
      end

      def format_duration(seconds)
        "#{(seconds * 1000).round(2)}ms"
      end
    end
  end
end