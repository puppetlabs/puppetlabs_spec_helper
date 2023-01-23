require 'spec_helper'

describe Puppet::Type.type(:package).provider(:macports) do
  let :resource_name do
    "foo"
  end

  let :resource do
    Puppet::Type.type(:package).new(:name => resource_name, :provider => :macports)
  end

  let :provider do
    prov = resource.provider
    expect(prov).not_to receive(:execute)
    prov
  end

  let :current_hash do
    {:name => resource_name, :ensure => "1.2.3", :revision => "1", :provider => :macports}
  end

  context "provider features" do
    subject { provider }

    it { is_expected.to be_installable }
    it { is_expected.to be_uninstallable }
    it { is_expected.to be_upgradeable }
    it { is_expected.to be_versionable }
  end

  context "when listing all instances" do
    it "should call port -q installed" do
      expect(described_class).to receive(:port).with("-q", :installed).and_return("")
      described_class.instances
    end

    it "should create instances from active ports" do
      expect(described_class).to receive(:port).and_return("foo @1.234.5_2 (active)")
      expect(described_class.instances.size).to eq(1)
    end

    it "should ignore ports that aren't activated" do
      expect(described_class).to receive(:port).and_return("foo @1.234.5_2")
      expect(described_class.instances.size).to eq(0)
    end

    it "should ignore variants" do
      expect(described_class.parse_installed_query_line("bar @1.0beta2_38_1+x11+java (active)")).
        to eq({:provider=>:macports, :revision=>"1", :name=>"bar", :ensure=>"1.0beta2_38"})
    end

  end

  context "when installing" do
    it "should not specify a version when ensure is set to latest" do
      resource[:ensure] = :latest
      # version would be the 4th argument, if provided.
      expect(provider).to receive(:port).with(anything, anything, anything)

      provider.install
    end

    it "should not specify a version when ensure is set to present" do
      resource[:ensure] = :present
      # version would be the 4th argument, if provided.
      expect(provider).to receive(:port).with(anything, anything, anything)

      provider.install
    end

    it "should specify a version when ensure is set to a version" do
      resource[:ensure] = "1.2.3"
      expect(provider).to receive(:port).with(anything, anything, anything, '@1.2.3')

      provider.install
    end
  end

  context "when querying for the latest version" do
    # Redefine provider to avoid the "expect(prov).not_to receive(:execute)"
    # that was set in the original definition.
    let(:provider) { resource.provider }
    let(:new_info_line) do
      "1.2.3 2"
    end
    let(:infoargs) do
      ["/opt/local/bin/port", "-q", :info, "--line", "--version", "--revision",  resource_name]
    end
    let(:arguments) do
      {:failonfail => false, :combine => false}
    end

    before :each do
      allow(provider).to receive(:command).with(:port).and_return("/opt/local/bin/port")
    end

    it "should return nil when the package cannot be found" do
      resource[:name] = resource_name
      expect(provider).to receive(:execute).with(infoargs, arguments).and_return("")
      expect(provider.latest).to eq(nil)
    end

    it "should return the current version if the installed port has the same revision" do
      current_hash[:revision] = "2"
      expect(provider).to receive(:execute).with(infoargs, arguments).and_return(new_info_line)
      expect(provider).to receive(:query).and_return(current_hash)
      expect(provider.latest).to eq(current_hash[:ensure])
    end

    it "should return the new version_revision if the installed port has a lower revision" do
      current_hash[:revision] = "1"
      expect(provider).to receive(:execute).with(infoargs, arguments).and_return(new_info_line)
      expect(provider).to receive(:query).and_return(current_hash)
      expect(provider.latest).to eq("1.2.3_2")
    end

    it "should return the newest version if the port is not installed" do
      resource[:name] = resource_name
      expect(provider).to receive(:execute).with(infoargs, arguments).and_return(new_info_line)
      expect(provider).to receive(:execute).with(["/opt/local/bin/port", "-q", :installed, resource[:name]], arguments).and_return("")
      expect(provider.latest).to eq("1.2.3_2")
    end
  end

  context "when updating a port" do
    it "should execute port install if the port is installed" do
      resource[:name] = resource_name
      resource[:ensure] = :present
      allow(provider).to receive(:query).and_return(current_hash)
      expect(provider).to receive(:port).with("-q", :install, resource_name)
      provider.update
    end

    it "should execute port install if the port is not installed" do
      resource[:name] = resource_name
      resource[:ensure] = :present
      allow(provider).to receive(:query).and_return("")
      expect(provider).to receive(:port).with("-q", :install, resource_name)
      provider.update
    end
  end
end
