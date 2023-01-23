require 'spec_helper'

describe Puppet::Type.type(:group) do
  before do
    @class = Puppet::Type.type(:group)
  end

  it "should have a system_groups feature" do
    expect(@class.provider_feature(:system_groups)).not_to be_nil
  end

  it 'should default to `present`' do
    expect(@class.new(:name => "foo")[:ensure]).to eq(:present)
  end

  it 'should set ensure to whatever is passed in' do
    expect(@class.new(:name => "foo", :ensure => 'absent')[:ensure]).to eq(:absent)
  end

  describe "when validating attributes" do
    [:name, :allowdupe].each do |param|
      it "should have a #{param} parameter" do
        expect(@class.attrtype(param)).to eq(:param)
      end
    end

    [:ensure, :gid].each do |param|
      it "should have a #{param} property" do
        expect(@class.attrtype(param)).to eq(:property)
      end
    end

    it "should convert gids provided as strings into integers" do
      expect(@class.new(:name => "foo", :gid => "15")[:gid]).to eq(15)
    end

    it "should accepts gids provided as integers" do
      expect(@class.new(:name => "foo", :gid => 15)[:gid]).to eq(15)
    end
  end

  it "should have a boolean method for determining if duplicates are allowed" do
    expect(@class.new(:name => "foo")).to respond_to "allowdupe?"
  end

  it "should have a boolean method for determining if system groups are allowed" do
    expect(@class.new(:name => "foo")).to respond_to "system?"
  end

  it "should call 'create' to create the group" do
    group = @class.new(:name => "foo", :ensure => :present)
    expect(group.provider).to receive(:create)
    group.parameter(:ensure).sync
  end

  it "should call 'delete' to remove the group" do
    group = @class.new(:name => "foo", :ensure => :absent)
    expect(group.provider).to receive(:delete)
    group.parameter(:ensure).sync
  end

  it "delegates the existence check to its provider" do
    provider = @class.provide(:testing) do
      def exists?
        true
      end
    end
    provider_instance = provider.new

    type = @class.new(:name => "group", :provider => provider_instance)

    expect(type.exists?).to eq(true)
  end

  describe "should delegate :members implementation to the provider:"  do
    let (:provider) do
      @class.provide(:testing) do
        has_features :manages_members

        def members
          []
        end

        def members_insync?(current, should)
          current == should
        end

        def members_to_s(values)
          values.map { |v| "#{v} ()" }.join(', ')
        end
      end
    end
    let (:provider_instance) { provider.new }
    let (:type) { @class.new(:name => "group", :provider => provider_instance, :members => ['user1']) }

    it "insync? calls members_insync?" do
      expect(type.property(:members).insync?(['user1'])).to be_truthy
    end

    it "is_to_s and should_to_s call members_to_s" do
      expect(type.property(:members).is_to_s('user1')).to eq('user1 ()')
      expect(type.property(:members).should_to_s('user1,user2')).to eq('user1 (), user2 ()')
    end
  end
end
