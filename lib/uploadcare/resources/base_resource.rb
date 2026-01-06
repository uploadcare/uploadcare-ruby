# frozen_string_literal: true

module Uploadcare
  class BaseResource
    attr_accessor :config

    def initialize(attributes = {}, config = Uploadcare.configuration)
      @config = config
      assign_attributes(attributes)
    end

    protected

    def rest_client
      @rest_client ||= Uploadcare::RestClient.new(@config)
    end

    private

    def assign_attributes(attributes)
      attributes.each do |key, value|
        setter = "#{key}="
        send(setter, value) if respond_to?(setter)
      end
    end
  end
end
