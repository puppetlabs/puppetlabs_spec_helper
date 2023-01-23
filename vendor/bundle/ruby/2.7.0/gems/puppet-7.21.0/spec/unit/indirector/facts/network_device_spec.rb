require 'spec_helper'

require 'puppet/util/network_device'
require 'puppet/indirector/facts/network_device'

describe Puppet::Node::Facts::NetworkDevice do
  it "should be a subclass of the Code terminus" do
    expect(Puppet::Node::Facts::NetworkDevice.superclass).to equal(Puppet::Indirector::Code)
  end

  it "should have documentation" do
    expect(Puppet::Node::Facts::NetworkDevice.doc).not_to be_nil
  end

  it "should be registered with the configuration store indirection" do
    indirection = Puppet::Indirector::Indirection.instance(:facts)
    expect(Puppet::Node::Facts::NetworkDevice.indirection).to equal(indirection)
  end

  it "should have its name set to :facter" do
    expect(Puppet::Node::Facts::NetworkDevice.name).to eq(:network_device)
  end
end

describe Puppet::Node::Facts::NetworkDevice do
  before :each do
    @remote_device = double('remote_device', :facts => {})
    allow(Puppet::Util::NetworkDevice).to receive(:current).and_return(@remote_device)
    @device = Puppet::Node::Facts::NetworkDevice.new
    @name = "me"
    @request = double('request', :key => @name)
  end

  describe Puppet::Node::Facts::NetworkDevice, " when finding facts" do
    it "should return a Facts instance" do
      expect(@device.find(@request)).to be_instance_of(Puppet::Node::Facts)
    end

    it "should return a Facts instance with the provided key as the name" do
      expect(@device.find(@request).name).to eq(@name)
    end

    it "should return the device facts as the values in the Facts instance" do
      expect(@remote_device).to receive(:facts).and_return("one" => "two")
      facts = @device.find(@request)
      expect(facts.values["one"]).to eq("two")
    end

    it "should add local facts" do
      facts = Puppet::Node::Facts.new("foo")
      expect(Puppet::Node::Facts).to receive(:new).and_return(facts)
      expect(facts).to receive(:add_local_facts)

      @device.find(@request)
    end

    it "should sanitize facts" do
      facts = Puppet::Node::Facts.new("foo")
      expect(Puppet::Node::Facts).to receive(:new).and_return(facts)
      expect(facts).to receive(:sanitize)

      @device.find(@request)
    end
  end

  describe Puppet::Node::Facts::NetworkDevice, " when saving facts" do
    it "should fail" do
      expect { @device.save(@facts) }.to raise_error(Puppet::DevError)
    end
  end

  describe Puppet::Node::Facts::NetworkDevice, " when destroying facts" do
    it "should fail" do
      expect { @device.destroy(@facts) }.to raise_error(Puppet::DevError)
    end
  end
end
