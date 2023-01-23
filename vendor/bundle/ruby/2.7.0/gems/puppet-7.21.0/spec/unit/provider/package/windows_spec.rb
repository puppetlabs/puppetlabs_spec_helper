require 'spec_helper'

describe Puppet::Type.type(:package).provider(:windows), :if => Puppet.features.microsoft_windows? do
  let(:name)        { 'mysql-5.1.58-win-x64' }
  let(:source)      { 'E:\Rando\Directory\mysql-5.1.58-win-x64.msi' }
  let(:resource)    {  Puppet::Type.type(:package).new(:name => name, :provider => :windows, :source => source) }
  let(:provider)    { resource.provider }
  let(:execute_options) do {:failonfail => false, :combine => true, :suppress_window => true} end

  before(:each) do
    # make sure we never try to execute anything
    @times_execute_called = 0
    allow(provider).to receive(:execute) { @times_execute_called += 1}
  end

  after(:each) do
    expect(@times_execute_called).to eq(0)
  end

  def expect_execute(command, status)
    expect(provider).to receive(:execute).with(command, execute_options).and_return(Puppet::Util::Execution::ProcessOutput.new('',status))
  end

  describe 'provider features' do
    it { is_expected.to be_installable }
    it { is_expected.to be_uninstallable }
    it { is_expected.to be_install_options }
    it { is_expected.to be_uninstall_options }
    it { is_expected.to be_versionable }
  end

  describe 'on Windows', :if => Puppet::Util::Platform.windows? do
    it 'should be the default provider' do
      expect(Puppet::Type.type(:package).defaultprovider).to eq(subject.class)
    end
  end

  context '::instances' do
    it 'should return an array of provider instances' do
      pkg1 = double('pkg1')
      pkg2 = double('pkg2')

      prov1 = double('prov1', :name => 'pkg1', :version => '1.0.0', :package => pkg1)
      prov2 = double('prov2', :name => 'pkg2', :version => nil, :package => pkg2)

      expect(Puppet::Provider::Package::Windows::Package).to receive(:map).and_yield(prov1).and_yield(prov2).and_return([prov1, prov2])

      providers = provider.class.instances
      expect(providers.count).to eq(2)
      expect(providers[0].name).to eq('pkg1')
      expect(providers[0].version).to eq('1.0.0')
      expect(providers[0].package).to eq(pkg1)

      expect(providers[1].name).to eq('pkg2')
      expect(providers[1].version).to be_nil
      expect(providers[1].package).to eq(pkg2)
    end

    it 'should return an empty array if none found' do
      expect(Puppet::Provider::Package::Windows::Package).to receive(:map).and_return([])

      expect(provider.class.instances).to eq([])
    end
  end

  context '#query' do
    it 'should return the hash of the matched packaged' do
      pkg = double(:name => 'pkg1', :version => nil)
      expect(pkg).to receive(:match?).and_return(true)
      expect(Puppet::Provider::Package::Windows::Package).to receive(:find).and_yield(pkg)

      expect(provider.query).to eq({ :name => 'pkg1', :ensure => :installed, :provider => :windows })
    end

    it 'should include the version string when present' do
      pkg = double(:name => 'pkg1', :version => '1.0.0')
      expect(pkg).to receive(:match?).and_return(true)
      expect(Puppet::Provider::Package::Windows::Package).to receive(:find).and_yield(pkg)

      expect(provider.query).to eq({ :name => 'pkg1', :ensure => '1.0.0', :provider => :windows })
    end

    it 'should return nil if no package was found' do
      expect(Puppet::Provider::Package::Windows::Package).to receive(:find)

      expect(provider.query).to be_nil
    end
  end

  context '#install' do
    let(:command) { 'blarg.exe /S' }
    let(:klass) { double('installer', :install_command => ['blarg.exe', '/S'] ) }
    let(:execute_options) do {:failonfail => false, :combine => true, :cwd => nil, :suppress_window => true} end
    before :each do
      expect(Puppet::Provider::Package::Windows::Package).to receive(:installer_class).and_return(klass)
    end

    it 'should join the install command and options' do
      resource[:install_options] = { 'INSTALLDIR' => 'C:\mysql-5.1' }

      expect_execute("#{command} INSTALLDIR=C:\\mysql-5.1", 0)

      provider.install
    end

    it 'should compact nil install options' do
      expect_execute(command, 0)

      provider.install
    end

    it 'should not warn if the package install succeeds' do
      expect_execute(command, 0)
      expect(provider).not_to receive(:warning)

      provider.install
    end

    it 'should warn if reboot initiated' do
      expect_execute(command, 1641)
      expect(provider).to receive(:warning).with('The package installed successfully and the system is rebooting now.')

      provider.install
    end

    it 'should warn if reboot required' do
      expect_execute(command, 3010)
      expect(provider).to receive(:warning).with('The package installed successfully, but the system must be rebooted.')

      provider.install
    end

    it 'should fail otherwise', :if => Puppet::Util::Platform.windows? do
      expect_execute(command, 5)

      expect do
        provider.install
      end.to raise_error do |error|
        expect(error).to be_a(Puppet::Util::Windows::Error)
        expect(error.code).to eq(5) # ERROR_ACCESS_DENIED
      end
    end

    context 'With a real working dir' do
      let(:execute_options) do {:failonfail => false, :combine => true, :cwd => 'E:\Rando\Directory', :suppress_window => true} end

      it 'should not try to set the working directory' do
        expect(Puppet::FileSystem).to receive(:exist?).with('E:\Rando\Directory').and_return(true)
        expect_execute(command, 0)

        provider.install
      end
    end
  end

  context '#uninstall' do
    let(:command) { 'unblarg.exe /Q' }
    let(:package) { double('package', :uninstall_command => ['unblarg.exe', '/Q'] ) }

    before :each do
      resource[:ensure] = :absent
      provider.package = package
    end

    it 'should join the uninstall command and options' do
      resource[:uninstall_options] = { 'INSTALLDIR' => 'C:\mysql-5.1' }
      expect_execute("#{command} INSTALLDIR=C:\\mysql-5.1", 0)

      provider.uninstall
    end

    it 'should compact nil install options' do
      expect_execute(command, 0)

      provider.uninstall
    end

    it 'should not warn if the package install succeeds' do
      expect_execute(command, 0)
      expect(provider).not_to receive(:warning)

      provider.uninstall
    end

    it 'should warn if reboot initiated' do
      expect_execute(command, 1641)
      expect(provider).to receive(:warning).with('The package uninstalled successfully and the system is rebooting now.')

      provider.uninstall
    end

    it 'should warn if reboot required' do
      expect_execute(command, 3010)
      expect(provider).to receive(:warning).with('The package uninstalled successfully, but the system must be rebooted.')

      provider.uninstall
    end

    it 'should fail otherwise', :if => Puppet::Util::Platform.windows? do
      expect_execute(command, 5)

      expect do
        provider.uninstall
      end.to raise_error do |error|
        expect(error).to be_a(Puppet::Util::Windows::Error)
        expect(error.code).to eq(5) # ERROR_ACCESS_DENIED
      end
    end
  end

  context '#validate_source' do
    it 'should fail if the source parameter is empty' do
      expect do
        resource[:source] = ''
      end.to raise_error(Puppet::Error, /The source parameter cannot be empty when using the Windows provider/)
    end

    it 'should accept a source' do
      resource[:source] = source
    end
  end

  context '#install_options' do
    it 'should return nil by default' do
      expect(provider.install_options).to be_nil
    end

    it 'should return the options' do
      resource[:install_options] = { 'INSTALLDIR' => 'C:\mysql-here' }

      expect(provider.install_options).to eq(['INSTALLDIR=C:\mysql-here'])
    end

    it 'should only quote if needed' do
      resource[:install_options] = { 'INSTALLDIR' => 'C:\mysql here' }

      expect(provider.install_options).to eq(['INSTALLDIR="C:\mysql here"'])
    end

    it 'should escape embedded quotes in install_options values with spaces' do
      resource[:install_options] = { 'INSTALLDIR' => 'C:\mysql "here"' }

      expect(provider.install_options).to eq(['INSTALLDIR="C:\mysql \"here\""'])
    end
  end

  context '#uninstall_options' do
    it 'should return nil by default' do
      expect(provider.uninstall_options).to be_nil
    end

    it 'should return the options' do
      resource[:uninstall_options] = { 'INSTALLDIR' => 'C:\mysql-here' }

      expect(provider.uninstall_options).to eq(['INSTALLDIR=C:\mysql-here'])
    end
  end

  context '#join_options' do
    it 'should return nil if there are no options' do
      expect(provider.join_options(nil)).to be_nil
    end

    it 'should sort hash keys' do
      expect(provider.join_options([{'b' => '2', 'a' => '1', 'c' => '3'}])).to eq(['a=1', 'b=2', 'c=3'])
    end

    it 'should return strings and hashes' do
      expect(provider.join_options([{'a' => '1'}, 'b'])).to eq(['a=1', 'b'])
    end
  end
end
