require 'spec_helper'
require 'puppet/pops'
require 'puppet/loaders'

describe 'the match function' do

  before(:each) do
    loaders = Puppet::Pops::Loaders.new(Puppet::Node::Environment.create(:testing, []))
    Puppet.push_context({:loaders => loaders}, "test-examples")
  end

  after(:each) do
    Puppet.pop_context()
  end

  let(:func) do
    Puppet.lookup(:loaders).puppet_system_loader.load(:function, 'match')
  end

  let(:type_parser) { Puppet::Pops::Types::TypeParser.singleton }


  it 'matches string and regular expression without captures' do
    expect(func.call({}, 'abc123', /[a-z]+[1-9]+/)).to eql(['abc123'])
  end

  it 'matches string and regular expression with captures' do
    expect(func.call({}, 'abc123', /([a-z]+)([1-9]+)/)).to eql(['abc123', 'abc', '123'])
  end

  it 'produces nil if match is not found' do
    expect(func.call({}, 'abc123', /([x]+)([6]+)/)).to be_nil
  end

  [ 'Pattern[/([a-z]+)([1-9]+)/]',       # regexp
    'Pattern["([a-z]+)([1-9]+)"]',       # string
    'Regexp[/([a-z]+)([1-9]+)/]',        # regexp type
    'Pattern[/x9/, /([a-z]+)([1-9]+)/]', # regexp, first found matches
  ].each do |pattern|
    it "matches string and type #{pattern} with captures" do
      expect(func.call({}, 'abc123', type(pattern))).to eql(['abc123', 'abc', '123'])
    end

    it "matches string with an alias type for #{pattern} with captures" do
      expect(func.call({}, 'abc123', alias_type("MyAlias", type(pattern)))).to eql(['abc123', 'abc', '123'])
    end

    it "matches string with a  matching variant type for #{pattern} with captures" do
      expect(func.call({}, 'abc123', variant_type(type(pattern)))).to eql(['abc123', 'abc', '123'])
    end

  end

  it 'matches an array of strings and yields a map of the result' do
    expect(func.call({}, ['abc123', '2a', 'xyz2'], /([a-z]+)[1-9]+/)).to eql([['abc123', 'abc'], nil, ['xyz2', 'xyz']])
  end

  it 'raises error if Regexp type without regexp is used' do
    expect{func.call({}, 'abc123', type('Regexp'))}.to raise_error(ArgumentError, /Given Regexp Type has no regular expression/)
  end

  def variant_type(*t)
    Puppet::Pops::Types::PVariantType.new(t)
  end

  def alias_type(name, t)
    # Create an alias using a nil AST (which is never used because it is given a type as resolution)
    Puppet::Pops::Types::PTypeAliasType.new(name, nil, t)
  end

  def type(s)
    Puppet::Pops::Types::TypeParser.singleton.parse(s)
  end
end
