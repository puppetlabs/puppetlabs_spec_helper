require 'spec_helper'

describe Puppet::Type.type(:group).provider(:ldap) do
  it "should have the Ldap provider class as its baseclass" do
    expect(described_class.superclass).to equal(Puppet::Provider::Ldap)
  end

  it "should manage :posixGroup objectclass" do
    expect(described_class.manager.objectclasses).to eq([:posixGroup])
  end

  it "should use 'ou=Groups' as its relative base" do
    expect(described_class.manager.location).to eq("ou=Groups")
  end

  it "should use :cn as its rdn" do
    expect(described_class.manager.rdn).to eq(:cn)
  end

  it "should map :name to 'cn'" do
    expect(described_class.manager.ldap_name(:name)).to eq('cn')
  end

  it "should map :gid to 'gidNumber'" do
    expect(described_class.manager.ldap_name(:gid)).to eq('gidNumber')
  end

  it "should map :members to 'memberUid', to be used by the user ldap provider" do
    expect(described_class.manager.ldap_name(:members)).to eq('memberUid')
  end

  describe "when being created" do
    before do
      # So we don't try to actually talk to ldap
      @connection = double('connection')
      allow(described_class.manager).to receive(:connect).and_yield(@connection)
    end

    describe "with no gid specified" do
      it "should pick the first available GID after the largest existing GID" do
        low = {:name=>["luke"], :gid=>["600"]}
        high = {:name=>["testing"], :gid=>["640"]}
        expect(described_class.manager).to receive(:search).and_return([low, high])

        resource = double('resource', :should => %w{whatever})
        allow(resource).to receive(:should).with(:gid).and_return(nil)
        allow(resource).to receive(:should).with(:ensure).and_return(:present)
        instance = described_class.new(:name => "luke", :ensure => :absent)
        allow(instance).to receive(:resource).and_return(resource)

        expect(@connection).to receive(:add).with(anything, hash_including("gidNumber" => ["641"]))

        instance.create
        instance.flush
      end

      it "should pick '501' as its GID if no groups are found" do
        expect(described_class.manager).to receive(:search).and_return(nil)

        resource = double('resource', :should => %w{whatever})
        allow(resource).to receive(:should).with(:gid).and_return(nil)
        allow(resource).to receive(:should).with(:ensure).and_return(:present)
        instance = described_class.new(:name => "luke", :ensure => :absent)
        allow(instance).to receive(:resource).and_return(resource)

        expect(@connection).to receive(:add).with(anything, hash_including("gidNumber" => ["501"]))

        instance.create
        instance.flush
      end
    end
  end

  it "should have a method for converting group names to GIDs" do
    expect(described_class).to respond_to(:name2id)
  end

  describe "when converting from a group name to GID" do
    it "should use the ldap manager to look up the GID" do
      expect(described_class.manager).to receive(:search).with("cn=foo")
      described_class.name2id("foo")
    end

    it "should return nil if no group is found" do
      expect(described_class.manager).to receive(:search).with("cn=foo").and_return(nil)
      expect(described_class.name2id("foo")).to be_nil
      expect(described_class.manager).to receive(:search).with("cn=bar").and_return([])
      expect(described_class.name2id("bar")).to be_nil
    end

    # We shouldn't ever actually have more than one gid, but it doesn't hurt
    # to test for the possibility.
    it "should return the first gid from the first returned group" do
      expect(described_class.manager).to receive(:search).with("cn=foo").and_return([{:name => "foo", :gid => [10, 11]}, {:name => :bar, :gid => [20, 21]}])
      expect(described_class.name2id("foo")).to eq(10)
    end
  end
end
