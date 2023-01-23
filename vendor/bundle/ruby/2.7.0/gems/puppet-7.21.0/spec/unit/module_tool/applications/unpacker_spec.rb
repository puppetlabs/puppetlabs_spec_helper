require 'spec_helper'
require 'puppet/util/json'

require 'puppet/module_tool/applications'
require 'puppet/file_system'
require 'puppet_spec/modules'

describe Puppet::ModuleTool::Applications::Unpacker do
  include PuppetSpec::Files

  let(:target)      { tmpdir("unpacker") }
  let(:module_name) { 'myusername-mytarball' }
  let(:filename)    { tmpdir("module") + "/module.tar.gz" }
  let(:working_dir) { tmpdir("working_dir") }

  before :each do
    allow(Puppet.settings).to receive(:[])
    allow(Puppet.settings).to receive(:[]).with(:module_working_dir).and_return(working_dir)
  end

  it "should attempt to untar file to temporary location" do
    untar = double('Tar')
    expect(untar).to receive(:unpack).with(filename, anything, anything) do |src, dest, _|
      FileUtils.mkdir(File.join(dest, 'extractedmodule'))
      File.open(File.join(dest, 'extractedmodule', 'metadata.json'), 'w+') do |file|
        file.puts Puppet::Util::Json.dump('name' => module_name, 'version' => '1.0.0')
      end
      true
    end

    expect(Puppet::ModuleTool::Tar).to receive(:instance).and_return(untar)

    Puppet::ModuleTool::Applications::Unpacker.run(filename, :target_dir => target)
    expect(File).to be_directory(File.join(target, 'mytarball'))
  end

  it "should warn about symlinks", :if => Puppet.features.manages_symlinks? do
    untar = double('Tar')
    expect(untar).to receive(:unpack).with(filename, anything, anything) do |src, dest, _|
      FileUtils.mkdir(File.join(dest, 'extractedmodule'))
      File.open(File.join(dest, 'extractedmodule', 'metadata.json'), 'w+') do |file|
        file.puts Puppet::Util::Json.dump('name' => module_name, 'version' => '1.0.0')
      end
      FileUtils.touch(File.join(dest, 'extractedmodule/tempfile'))
      Puppet::FileSystem.symlink(File.join(dest, 'extractedmodule/tempfile'), File.join(dest, 'extractedmodule/tempfile2'))
      true
    end

    expect(Puppet::ModuleTool::Tar).to receive(:instance).and_return(untar)
    expect(Puppet).to receive(:warning).with(/symlinks/i)

    Puppet::ModuleTool::Applications::Unpacker.run(filename, :target_dir => target)
    expect(File).to be_directory(File.join(target, 'mytarball'))
  end

  it "should warn about symlinks in subdirectories", :if => Puppet.features.manages_symlinks? do
    untar = double('Tar')
    expect(untar).to receive(:unpack).with(filename, anything, anything) do |src, dest, _|
      FileUtils.mkdir(File.join(dest, 'extractedmodule'))
      File.open(File.join(dest, 'extractedmodule', 'metadata.json'), 'w+') do |file|
        file.puts Puppet::Util::Json.dump('name' => module_name, 'version' => '1.0.0')
      end
      FileUtils.mkdir(File.join(dest, 'extractedmodule/manifests'))
      FileUtils.touch(File.join(dest, 'extractedmodule/manifests/tempfile'))
      Puppet::FileSystem.symlink(File.join(dest, 'extractedmodule/manifests/tempfile'), File.join(dest, 'extractedmodule/manifests/tempfile2'))
      true
    end

    expect(Puppet::ModuleTool::Tar).to receive(:instance).and_return(untar)
    expect(Puppet).to receive(:warning).with(/symlinks/i)

    Puppet::ModuleTool::Applications::Unpacker.run(filename, :target_dir => target)
    expect(File).to be_directory(File.join(target, 'mytarball'))
  end
end
