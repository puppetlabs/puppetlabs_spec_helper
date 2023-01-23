require 'spec_helper'
require 'puppet/provider/package/windows/msi_package'

describe Puppet::Provider::Package::Windows::MsiPackage do
  let (:name)        { 'mysql-5.1.58-win-x64' }
  let (:version)     { '5.1.58' }
  let (:source)      { 'E:\mysql-5.1.58-win-x64.msi' }
  let (:productcode) { '{E437FFB6-5C49-4DAC-ABAE-33FF065FE7CC}' }
  let (:packagecode) { '{5A6FD560-763A-4BC1-9E03-B18DFFB7C72C}' }

  def expect_installer
    inst = double()
    expect(inst).to receive(:ProductState).and_return(5)
    expect(inst).to receive(:ProductInfo).with(productcode, 'PackageCode').and_return(packagecode)
    expect(described_class).to receive(:installer).and_return(inst)
  end

  context '::installer', :if => Puppet::Util::Platform.windows? do
    it 'should return an instance of the COM interface' do
      expect(described_class.installer).not_to be_nil
    end
  end

  context '::from_registry' do
    it 'should return an instance of MsiPackage' do
      expect(described_class).to receive(:valid?).and_return(true)
      expect_installer

      pkg = described_class.from_registry(productcode, {'DisplayName' => name, 'DisplayVersion' => version})
      expect(pkg.name).to eq(name)
      expect(pkg.version).to eq(version)
      expect(pkg.productcode).to eq(productcode)
      expect(pkg.packagecode).to eq(packagecode)
    end

    it 'should return nil if it is not a valid MSI' do
      expect(described_class).to receive(:valid?).and_return(false)

      expect(described_class.from_registry(productcode, {})).to be_nil
    end
  end

  context '::valid?' do
    let(:values) do { 'DisplayName' => name, 'DisplayVersion' => version, 'WindowsInstaller' => 1 } end

    {
      'DisplayName'      => ['My App', ''],
      'WindowsInstaller' => [1, nil],
    }.each_pair do |k, arr|
      it "should accept '#{k}' with value '#{arr[0]}'" do
        values[k] = arr[0]
        expect(described_class.valid?(productcode, values)).to be_truthy
      end

      it "should reject '#{k}' with value '#{arr[1]}'" do
        values[k] = arr[1]
        expect(described_class.valid?(productcode, values)).to be_falsey
      end
    end

    it 'should reject packages whose name is not a productcode' do
     expect(described_class.valid?('AddressBook', values)).to be_falsey
   end

   it 'should accept packages whose name is a productcode' do
     expect(described_class.valid?(productcode, values)).to be_truthy
   end
  end

  context '#match?' do
    it 'should match package codes case-insensitively' do
      pkg = described_class.new(name, version, productcode, packagecode.upcase)

      expect(pkg.match?({:name => packagecode.downcase})).to be_truthy
    end

    it 'should match product codes case-insensitively' do
      pkg = described_class.new(name, version, productcode.upcase, packagecode)

      expect(pkg.match?({:name => productcode.downcase})).to be_truthy
    end

    it 'should match product name' do
      pkg = described_class.new(name, version, productcode, packagecode)

      expect(pkg.match?({:name => name})).to be_truthy
    end

    it 'should return false otherwise' do
      pkg = described_class.new(name, version, productcode, packagecode)

      expect(pkg.match?({:name => 'not going to find it'})).to be_falsey
    end
  end

  context '#install_command' do
    it 'should install using the source' do
      cmd = described_class.install_command({:source => source})

      expect(cmd).to eq(['msiexec.exe', '/qn', '/norestart', '/i', source])
    end
  end

  context '#uninstall_command' do
    it 'should uninstall using the productcode' do
      pkg = described_class.new(name, version, productcode, packagecode)

      expect(pkg.uninstall_command).to eq(['msiexec.exe', '/qn', '/norestart', '/x', productcode])
    end
  end
end
