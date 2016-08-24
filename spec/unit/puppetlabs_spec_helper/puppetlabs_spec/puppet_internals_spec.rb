require 'spec_helper'
require 'puppetlabs_spec_helper/puppet_spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

# reset mock integration
RSpec.configure do |c|
  c.mock_with :rspec
end

describe PuppetlabsSpec::PuppetInternals do
  before(:all) do
    Puppet.initialize_settings
  end

  describe '.scope' do
    let(:subject) { described_class.scope }

    it 'should return a Puppet::Parser::Scope instance' do
      expect(subject).to be_a_kind_of Puppet::Parser::Scope
    end

    it 'should be suitable for function testing' do
      expect(subject.function_inline_template(['foo'])).to eq('foo')
    end

    it 'should accept a compiler' do
      compiler = described_class.compiler
      scope = described_class.scope(compiler: compiler)
      expect(scope.compiler).to eq(compiler)
    end

    it 'should have a source set' do
      scope = subject
      expect(scope.source).not_to be_nil
      expect(scope.source.name).to eq('foo')
    end
  end

  describe '.resource' do
    let(:subject) { described_class.resource }

    it 'can have a defined type' do
      expect(described_class.resource(type: :node).type).to eq(:node)
    end

    it 'defaults to a type of hostclass' do
      expect(subject.type).to eq(:hostclass)
    end

    it 'can have a defined name' do
      expect(described_class.resource(name: 'testingrsrc').name).to eq('testingrsrc')
    end

    it 'defaults to a name of testing' do
      expect(subject.name).to eq('testing')
    end
  end

  describe '.compiler' do
    let(:node) { described_class.node }

    it 'can have a defined node' do
      expect(described_class.compiler(node: node).node).to be node
    end
  end

  describe '.node' do
    it 'can have a defined name' do
      expect(described_class.node(name: 'mine').name).to eq('mine')
    end

    it 'can have a defined environment' do
      expect(described_class.node(environment: 'mine').environment.name).to eq(:mine)
    end

    it 'defaults to a name of testinghost' do
      expect(described_class.node.name).to eq('testinghost')
    end

    it 'accepts facts via options for rspec-puppet' do
      fact_values = { 'fqdn' => 'jeff.puppetlabs.com' }
      node = described_class.node(options: { parameters: fact_values })
      expect(node.parameters).to eq(fact_values)
    end
  end

  describe '.function_method' do
    it 'accepts an injected scope' do
      expect(Puppet::Parser::Functions).to receive(:function).with('my_func').and_return(true)
      scope = double(described_class.scope)
      scope.expects(:method).with(:function_my_func).returns(:fake_method)
      expect(described_class.function_method('my_func', scope: scope)).to eq(:fake_method)
    end

    it "returns nil if the function doesn't exist" do
      Puppet::Parser::Functions.expects(:function).with('my_func').returns(false)
      scope = double(described_class.scope)
      expect(described_class.function_method('my_func', scope: scope)).to be_nil
    end
  end
end
