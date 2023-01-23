require 'spec_helper'
require 'puppet/face'

describe Puppet::Face[:config, '0.0.1'] do

  let(:config) { described_class }

  def render(action, result)
    config.get_action(action).when_rendering(:console).call(result)
  end

  FS = Puppet::FileSystem

  it "prints a single setting without the name" do
    Puppet[:trace] = true

    result = subject.print("trace")
    expect(render(:print, result)).to eq("true\n")
  end

  it "prints multiple settings with the names" do
    Puppet[:trace] = true
    Puppet[:syslogfacility] = "file"

    result = subject.print("trace", "syslogfacility")
    expect(render(:print, result)).to eq(<<-OUTPUT)
syslogfacility = file
trace = true
    OUTPUT
  end

  it "prints environment_timeout=unlimited correctly" do
    Puppet[:environment_timeout] = "unlimited"

    result = subject.print("environment_timeout")
    expect(render(:print, result)).to eq("unlimited\n")
  end

  it "prints arrays correctly" do
    pending "Still doesn't print arrays like they would appear in config"
    Puppet[:server_list] = %w{server1 server2}

    result = subject.print("server_list")
    expect(render(:print, result)).to eq("server1, server2\n")
  end

  it "prints the setting from the selected section" do
    Puppet.settings.parse_config(<<-CONF)
    [user]
    syslogfacility = file
    CONF

    result = subject.print("syslogfacility", :section => "user")
    expect(render(:print, result)).to eq("file\n")
  end

  it "prints the section and environment, and not a warning, when a section is given and verbose is set" do
    Puppet.settings.parse_config(<<-CONF)
    [user]
    syslogfacility = file
    CONF

    #This has to be after the settings above, which resets the value
    Puppet[:log_level] = 'info'

    expect(Puppet).not_to receive(:warning)
    expect {
      result = subject.print("syslogfacility", :section => "user")
      expect(render(:print, result)).to eq("file\n")
    }.to output("\e[1;33mResolving settings from section 'user' in environment 'production'\e[0m\n").to_stderr
  end

  it "prints a warning and the section and environment when no section is given and verbose is set" do
    Puppet[:log_level] = 'info'
    Puppet[:trace] = true

    expect(Puppet).to receive(:warning).with("No section specified; defaulting to 'main'.\nSet the config section " +
      "by using the `--section` flag.\nFor example, `puppet config --section user print foo`.\nFor more " +
      "information, see https://puppet.com/docs/puppet/latest/configuration.html")
    expect {
      result = subject.print("trace")
      expect(render(:print, result)).to eq("true\n")
    }.to output("\e[1;33mResolving settings from section 'main' in environment 'production'\e[0m\n").to_stderr
  end

  it "does not print a warning or the section and environment when no section is given and verbose is not set" do
    Puppet[:log_level] = 'notice'
    Puppet[:trace] = true

    expect(Puppet).not_to receive(:warning)
    expect {
      result = subject.print("trace")
      expect(render(:print, result)).to eq("true\n")
    }.to_not output.to_stderr
  end

  it "defaults to all when no arguments are given" do
    result = subject.print
    expect(render(:print, result).lines.to_a.length).to eq(Puppet.settings.to_a.length)
  end

  it "prints out all of the settings when asked for 'all'" do
    result = subject.print('all')
    expect(render(:print, result).lines.to_a.length).to eq(Puppet.settings.to_a.length)
  end

  it "stringifies all keys for network format handlers to consume" do
    Puppet[:syslogfacility] = "file"

    result = subject.print
    expect(result["syslogfacility"]).to eq("file")
    expect(result.keys).to all(be_a(String))
  end

  it "stringifies multiple keys for network format handlers to consume" do
    Puppet[:trace] = true
    Puppet[:syslogfacility] = "file"

    expect(subject.print("trace", "syslogfacility")).to eq({"syslogfacility" => "file", "trace" => true})
  end

  it "stringifies single key for network format handlers to consume" do
    Puppet[:trace] = true

    expect(subject.print("trace")).to eq({"trace" => true})
  end

  context "when setting config values" do
    let(:config_file) { '/foo/puppet.conf' }
    let(:path) { Pathname.new(config_file).expand_path }
    before(:each) do
      Puppet[:config] = config_file
      allow(Puppet::FileSystem).to receive(:pathname).with(path.to_s).and_return(path)
      allow(Puppet::FileSystem).to receive(:touch)
    end

    it "prints the section and environment when no section is given and verbose is set" do
      Puppet[:log_level] = 'info'
      allow(Puppet::FileSystem).to receive(:open).with(path, anything, anything).and_yield(StringIO.new)
      expect {
        subject.set('certname', 'bar')
      }.to output("\e[1;33mResolving settings from section 'main' in environment 'production'\e[0m\n").to_stderr
    end

    it "prints the section and environment when a section is given and verbose is set" do
      Puppet[:log_level] = 'info'
      allow(Puppet::FileSystem).to receive(:open).with(path, anything, anything).and_yield(StringIO.new)
      expect {
        subject.set('certname', 'bar', {:section => "baz"})
      }.to output("\e[1;33mResolving settings from section 'baz' in environment 'production'\e[0m\n").to_stderr
    end

    it "writes to the correct puppet config file" do
      expect(Puppet::FileSystem).to receive(:open).with(path, anything, anything)
      subject.set('certname', 'bar')
    end

    it "creates a config file if one does not exist" do
      allow(Puppet::FileSystem).to receive(:open).with(path, anything, anything).and_yield(StringIO.new)
      expect(Puppet::FileSystem).to receive(:touch).with(path)
      subject.set('certname', 'bar')
    end

    it "sets the supplied config/value in the default section (main)" do
      allow(Puppet::FileSystem).to receive(:open).with(path, anything, anything).and_yield(StringIO.new)
      config = Puppet::Settings::IniFile.new([Puppet::Settings::IniFile::DefaultSection.new])
      manipulator = Puppet::Settings::IniFile::Manipulator.new(config)
      allow(Puppet::Settings::IniFile::Manipulator).to receive(:new).and_return(manipulator)

      expect(manipulator).to receive(:set).with("main", "certname", "bar")
      subject.set('certname', 'bar')
    end

    it "sets the value in the supplied section" do
      allow(Puppet::FileSystem).to receive(:open).with(path, anything, anything).and_yield(StringIO.new)
      config = Puppet::Settings::IniFile.new([Puppet::Settings::IniFile::DefaultSection.new])
      manipulator = Puppet::Settings::IniFile::Manipulator.new(config)
      allow(Puppet::Settings::IniFile::Manipulator).to receive(:new).and_return(manipulator)

      expect(manipulator).to receive(:set).with("baz", "certname", "bar")
      subject.set('certname', 'bar', {:section => "baz"})
    end

    it "does not duplicate an existing default section when a section is not specified" do
      contents = <<-CONF
      [main]
      myport = 4444
      CONF

      myfile = StringIO.new(contents)
      allow(Puppet::FileSystem).to receive(:open).with(path, anything, anything).and_yield(myfile)

      subject.set('certname', 'bar')

      expect(myfile.string).to match(/certname = bar/)
      expect(myfile.string).not_to match(/main.*main/)
    end

    it "opens the file with UTF-8 encoding" do
      expect(Puppet::FileSystem).to receive(:open).with(path, nil, 'r+:UTF-8')
      subject.set('certname', 'bar')
    end

    it "sets settings into the [server] section when setting [master] section settings" do
      initial_contents = <<~CONFIG
        [master]
        node_terminus = none
        reports = log
      CONFIG

      myinitialfile = StringIO.new(initial_contents)
      allow(Puppet::FileSystem).to receive(:open).with(path, anything, anything).and_yield(myinitialfile)

      expect {
        subject.set('node_terminus', 'exec', {:section => 'master'})
      }.to output("Deleted setting from 'master': 'node_terminus = none', and adding it to 'server' section\n").to_stdout

      expect(myinitialfile.string).to match(<<~CONFIG)
        [master]
        reports = log
        [server]
        node_terminus = exec
      CONFIG
    end

    it "setting [master] section settings, sets settings into [server] section instead" do
      myinitialfile = StringIO.new("")
      allow(Puppet::FileSystem).to receive(:open).with(path, anything, anything).and_yield(myinitialfile)
      subject.set('node_terminus', 'exec', {:section => 'master'})

      expect(myinitialfile.string).to match(<<~CONFIG)
        [server]
        node_terminus = exec
      CONFIG
    end
  end

  context 'when the puppet.conf file does not exist' do
    let(:config_file) { '/foo/puppet.conf' }
    let(:path) { Pathname.new(config_file).expand_path }

    before(:each) do
      Puppet[:config] = config_file
      allow(Puppet::FileSystem).to receive(:pathname).with(path.to_s).and_return(path)
    end

    it 'prints a message when the puppet.conf file does not exist' do
      allow(Puppet::FileSystem).to receive(:exist?).with(path).and_return(false)
      expect(Puppet).to receive(:warning).with("The puppet.conf file does not exist #{path.to_s}")
      subject.delete('setting', {:section => 'main'})
    end
  end

  context 'when deleting config values' do
    let(:config_file) { '/foo/puppet.conf' }
    let(:path) { Pathname.new(config_file).expand_path }
    before(:each) do
      Puppet[:config] = config_file
      allow(Puppet::FileSystem).to receive(:pathname).with(path.to_s).and_return(path)
      allow(Puppet::FileSystem).to receive(:exist?).with(path).and_return(true)
    end

    it 'prints a message about what was deleted' do
      allow(Puppet::FileSystem).to receive(:open).with(path, anything, anything).and_yield(StringIO.new)
      config = Puppet::Settings::IniFile.new([Puppet::Settings::IniFile::DefaultSection.new])
      manipulator = Puppet::Settings::IniFile::Manipulator.new(config)
      allow(Puppet::Settings::IniFile::Manipulator).to receive(:new).and_return(manipulator)

      expect(manipulator).to receive(:delete).with('main', 'setting').and_return('    setting=value')
      expect {
        subject.delete('setting', {:section => 'main'})
      }.to output("Deleted setting from 'main': 'setting=value'\n").to_stdout
    end

    it 'prints a warning when a setting is not found to delete' do
      allow(Puppet::FileSystem).to receive(:open).with(path, anything, anything).and_yield(StringIO.new)
      config = Puppet::Settings::IniFile.new([Puppet::Settings::IniFile::DefaultSection.new])
      manipulator = Puppet::Settings::IniFile::Manipulator.new(config)
      allow(Puppet::Settings::IniFile::Manipulator).to receive(:new).and_return(manipulator)

      expect(manipulator).to receive(:delete).with('main', 'setting').and_return(nil)
      expect(Puppet).to receive(:warning).with("No setting found in configuration file for section 'main' setting name 'setting'")
      subject.delete('setting', {:section => 'main'})
    end

    ['master', 'server'].each do |section|
      describe "when deleting from [#{section}] section" do
        it "deletes section values from both [server] and [master] sections" do
          allow(Puppet::FileSystem).to receive(:open).with(path, anything, anything).and_yield(StringIO.new)
          config = Puppet::Settings::IniFile.new([Puppet::Settings::IniFile::DefaultSection.new])
          manipulator = Puppet::Settings::IniFile::Manipulator.new(config)
          allow(Puppet::Settings::IniFile::Manipulator).to receive(:new).and_return(manipulator)

          expect(manipulator).to receive(:delete).with('master', 'setting').and_return('setting=value')
          expect(manipulator).to receive(:delete).with('server', 'setting').and_return('setting=value')
          expect {
            subject.delete('setting', {:section => section})
          }.to output(/Deleted setting from 'master': 'setting'\nDeleted setting from 'server': 'setting'\n/).to_stdout
        end
      end
    end

  end

  shared_examples_for :config_printing_a_section do |section|
    def add_section_option(args, section)
      args << { :section => section } if section
      args
    end

    it "prints directory env settings for an env that exists" do
      FS.overlay(
        FS::MemoryFile.a_directory(File.expand_path("/dev/null/environments"), [
          FS::MemoryFile.a_directory("production", [
            FS::MemoryFile.a_missing_file("environment.conf"),
          ]),
        ])
      ) do
        args = "environmentpath","manifest","modulepath","environment","basemodulepath"

        result = subject.print(*add_section_option(args, section))
        expect(render(:print, result)).to eq(<<-OUTPUT)
basemodulepath = #{File.expand_path("/some/base")}
environment = production
environmentpath = #{File.expand_path("/dev/null/environments")}
manifest = #{File.expand_path("/dev/null/environments/production/manifests")}
modulepath = #{File.expand_path("/dev/null/environments/production/modules")}#{File::PATH_SEPARATOR}#{File.expand_path("/some/base")}
        OUTPUT
      end
    end

    it "interpolates settings in environment.conf" do
      FS.overlay(
        FS::MemoryFile.a_directory(File.expand_path("/dev/null/environments"), [
          FS::MemoryFile.a_directory("production", [
            FS::MemoryFile.a_regular_file_containing("environment.conf", <<-CONTENT),
            modulepath=/custom/modules#{File::PATH_SEPARATOR}$basemodulepath
            CONTENT
          ]),
        ])
      ) do
        args = "environmentpath","manifest","modulepath","environment","basemodulepath"

        result = subject.print(*add_section_option(args, section))
        expect(render(:print, result)).to eq(<<-OUTPUT)
basemodulepath = #{File.expand_path("/some/base")}
environment = production
environmentpath = #{File.expand_path("/dev/null/environments")}
manifest = #{File.expand_path("/dev/null/environments/production/manifests")}
modulepath = #{File.expand_path("/custom/modules")}#{File::PATH_SEPARATOR}#{File.expand_path("/some/base")}
        OUTPUT
      end
    end

    it "prints the default configured env settings for an env that does not exist" do
      Puppet[:environment] = 'doesnotexist'

      FS.overlay(
        FS::MemoryFile.a_directory(File.expand_path("/dev/null/environments"), [
          FS::MemoryFile.a_missing_file("doesnotexist")
        ])
      ) do
        args = "environmentpath","manifest","modulepath","environment","basemodulepath"

        result = subject.print(*add_section_option(args, section))
        expect(render(:print, result)).to eq(<<-OUTPUT)
basemodulepath = #{File.expand_path("/some/base")}
environment = doesnotexist
environmentpath = #{File.expand_path("/dev/null/environments")}
manifest = 
modulepath = 
        OUTPUT
      end
    end
  end

  context "when printing environment settings" do
    context "from main section" do
      before(:each) do
        Puppet.settings.parse_config(<<-CONF)
        [main]
        environmentpath=$confdir/environments
        basemodulepath=/some/base
        CONF
      end

      it_behaves_like :config_printing_a_section, nil
    end

    context "from master section" do
      before(:each) do
        Puppet.settings.parse_config(<<-CONF)
        [master]
        environmentpath=$confdir/environments
        basemodulepath=/some/base
        CONF
      end

      it_behaves_like :config_printing_a_section, :master
    end
  end
end
