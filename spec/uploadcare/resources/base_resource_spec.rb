# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe BaseResource do
    let(:config) { Uploadcare.configuration }
    let(:attributes) { { 'name' => 'test', 'value' => 123 } }

    # Create a test subclass for testing
    let(:test_class) do
      Class.new(described_class) do
        attr_accessor :name, :value, :readonly_attr

        def readonly_attr
          @readonly_attr
        end
      end
    end

    subject { test_class.new(attributes, config) }

    describe '#initialize' do
      it 'sets config' do
        expect(subject.config).to eq(config)
      end

      it 'assigns attributes' do
        expect(subject.name).to eq('test')
        expect(subject.value).to eq(123)
      end

      it 'uses global config by default' do
        resource = test_class.new(attributes)

        expect(resource.config).to eq(Uploadcare.configuration)
      end

      it 'does not assign attributes without setters' do
        attrs = { 'name' => 'test', 'nonexistent' => 'should not set' }
        resource = test_class.new(attrs, config)

        expect(resource.name).to eq('test')
        expect(resource).not_to respond_to(:nonexistent)
      end
    end

    describe '#rest_client' do
      it 'returns a RestClient instance' do
        client = subject.send(:rest_client)

        expect(client).to be_a(Uploadcare::RestClient)
      end

      it 'uses the resource config' do
        client = subject.send(:rest_client)

        expect(client.instance_variable_get(:@config)).to eq(config)
      end

      it 'memoizes the client' do
        client1 = subject.send(:rest_client)
        client2 = subject.send(:rest_client)

        expect(client1).to be(client2)
      end
    end

    describe '#assign_attributes' do
      it 'assigns attributes with setters' do
        subject.send(:assign_attributes, { 'name' => 'updated', 'value' => 456 })

        expect(subject.name).to eq('updated')
        expect(subject.value).to eq(456)
      end

      it 'skips attributes without setters' do
        expect do
          subject.send(:assign_attributes, { 'nonexistent' => 'value' })
        end.not_to raise_error
      end

      it 'handles empty hash' do
        expect do
          subject.send(:assign_attributes, {})
        end.not_to raise_error
      end

      it 'handles string keys' do
        subject.send(:assign_attributes, { 'name' => 'string_key' })

        expect(subject.name).to eq('string_key')
      end
    end
  end
end
