# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::BaseResource do
  let(:config) { Uploadcare::Configuration.new(public_key: 'test_public', secret_key: 'test_secret') }

  # Create a test resource class
  let(:test_resource_class) do
    Class.new(described_class) do
      attr_accessor :uuid, :size, :is_ready, :metadata
    end
  end

  describe '#initialize' do
    context 'with attributes and config' do
      let(:attributes) do
        {
          uuid: '12345-67890',
          size: 1024,
          is_ready: true,
          metadata: { key: 'value' }
        }
      end

      let(:resource) { test_resource_class.new(attributes, config) }

      it 'assigns the configuration' do
        expect(resource.config).to eq(config)
      end

      it 'assigns all attributes' do
        expect(resource.uuid).to eq('12345-67890')
        expect(resource.size).to eq(1024)
        expect(resource.is_ready).to be(true)
        expect(resource.metadata).to eq({ key: 'value' })
      end
    end

    context 'with default configuration' do
      before do
        allow(Uploadcare).to receive(:configuration).and_return(config)
      end

      let(:resource) { test_resource_class.new(uuid: 'test-uuid') }

      it 'uses the default configuration' do
        expect(resource.config).to eq(config)
      end

      it 'assigns attributes' do
        expect(resource.uuid).to eq('test-uuid')
      end
    end

    context 'with unknown attributes' do
      let(:attributes) do
        {
          uuid: '12345',
          unknown_attribute: 'value',
          another_unknown: 123
        }
      end

      let(:resource) { test_resource_class.new(attributes, config) }

      it 'ignores unknown attributes' do
        expect(resource.uuid).to eq('12345')
        expect(resource).not_to respond_to(:unknown_attribute)
        expect(resource).not_to respond_to(:another_unknown)
      end

      it 'does not raise error' do
        expect { resource }.not_to raise_error
      end
    end

    context 'with empty attributes' do
      let(:resource) { test_resource_class.new({}, config) }

      it 'creates resource without errors' do
        expect(resource).to be_a(test_resource_class)
        expect(resource.uuid).to be_nil
        expect(resource.size).to be_nil
      end
    end

    context 'with nil attributes' do
      let(:resource) { test_resource_class.new(nil, config) }

      it 'handles nil gracefully' do
        expect { resource }.to raise_error(NoMethodError)
      end
    end
  end

  describe '#rest_client' do
    let(:resource) { test_resource_class.new({}, config) }

    it 'returns a RestClient instance' do
      expect(resource.send(:rest_client)).to be_a(Uploadcare::RestClient)
    end

    it 'memoizes the rest client' do
      client1 = resource.send(:rest_client)
      client2 = resource.send(:rest_client)
      expect(client1).to be(client2)
    end

    it 'uses the resource configuration' do
      rest_client = resource.send(:rest_client)
      expect(rest_client.instance_variable_get(:@config)).to eq(config)
    end
  end

  describe '#assign_attributes' do
    let(:resource) { test_resource_class.new({}, config) }

    it 'assigns multiple attributes' do
      resource.send(:assign_attributes, { uuid: 'new-uuid', size: 2048 })
      expect(resource.uuid).to eq('new-uuid')
      expect(resource.size).to eq(2048)
    end

    it 'only assigns attributes with setters' do
      resource.send(:assign_attributes, { uuid: 'test', non_existent: 'value' })
      expect(resource.uuid).to eq('test')
    end

    it 'handles boolean attributes' do
      resource.send(:assign_attributes, { is_ready: false })
      expect(resource.is_ready).to be(false)
    end

    it 'handles complex attributes' do
      complex_data = { nested: { data: [1, 2, 3] } }
      resource.send(:assign_attributes, { metadata: complex_data })
      expect(resource.metadata).to eq(complex_data)
    end
  end

  describe 'inheritance' do
    let(:child_class) do
      Class.new(test_resource_class) do
        attr_accessor :custom_field

        def custom_method
          'custom'
        end
      end
    end

    let(:child_resource) { child_class.new({ uuid: 'child-uuid', custom_field: 'custom' }, config) }

    it 'inherits initialization behavior' do
      expect(child_resource.uuid).to eq('child-uuid')
      expect(child_resource.custom_field).to eq('custom')
    end

    it 'inherits rest_client access' do
      expect(child_resource.send(:rest_client)).to be_a(Uploadcare::RestClient)
    end

    it 'can override methods' do
      expect(child_resource.custom_method).to eq('custom')
    end
  end

  describe 'edge cases' do
    context 'with string keys in attributes' do
      let(:attributes) { { 'uuid' => 'string-key-uuid', 'size' => 512 } }
      let(:resource) { test_resource_class.new(attributes, config) }

      it 'does not assign string keys' do
        expect(resource.uuid).to be_nil
        expect(resource.size).to be_nil
      end
    end

    context 'with mixed key types' do
      let(:attributes) { { uuid: 'symbol-uuid', 'size' => 1024 } }
      let(:resource) { test_resource_class.new(attributes, config) }

      it 'only assigns symbol keys' do
        expect(resource.uuid).to eq('symbol-uuid')
        expect(resource.size).to be_nil
      end
    end

    context 'with attribute writer that raises error' do
      let(:error_class) do
        Class.new(described_class) do
          attr_reader :value

          def value=(val)
            raise ArgumentError, 'Invalid value' if val == 'bad'

            @value = val
          end
        end
      end

      it 'propagates the error' do
        expect { error_class.new({ value: 'bad' }, config) }.to raise_error(ArgumentError, 'Invalid value')
      end
    end
  end
end
