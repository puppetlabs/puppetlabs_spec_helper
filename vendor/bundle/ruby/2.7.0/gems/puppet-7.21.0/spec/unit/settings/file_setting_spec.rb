require 'spec_helper'

require 'puppet/settings'
require 'puppet/settings/file_setting'

describe Puppet::Settings::FileSetting do
  FileSetting = Puppet::Settings::FileSetting

  include PuppetSpec::Files

  describe "when controlling permissions" do
    def settings(wanted_values = {})
       real_values = {
        :user => 'root',
        :group => 'root',
        :mkusers => false,
        :service_user_available? => false,
        :service_group_available? => false
      }.merge(wanted_values)

      settings = double("settings")

      allow(settings).to receive(:[]).with(:user).and_return(real_values[:user])
      allow(settings).to receive(:[]).with(:group).and_return(real_values[:group])
      allow(settings).to receive(:[]).with(:mkusers).and_return(real_values[:mkusers])
      allow(settings).to receive(:service_user_available?).and_return(real_values[:service_user_available?])
      allow(settings).to receive(:service_group_available?).and_return(real_values[:service_group_available?])

      settings
    end

    context "owner" do
      it "can always be root" do
        settings = settings(:user => "the_service", :mkusers => true)

        setting = FileSetting.new(:settings => settings, :owner => "root", :desc => "a setting")

        expect(setting.owner).to eq("root")
      end

      it "is the service user if we are making users" do
        settings = settings(:user => "the_service", :mkusers => true, :service_user_available? => false)

        setting = FileSetting.new(:settings => settings, :owner => "service", :desc => "a setting")

        expect(setting.owner).to eq("the_service")
      end

      it "is the service user if the user is available on the system" do
        settings = settings(:user => "the_service", :mkusers => false, :service_user_available? => true)

        setting = FileSetting.new(:settings => settings, :owner => "service", :desc => "a setting")

        expect(setting.owner).to eq("the_service")
      end

      it "is root when the setting specifies service and the user is not available on the system" do
        settings = settings(:user => "the_service", :mkusers => false, :service_user_available? => false)

        setting = FileSetting.new(:settings => settings, :owner => "service", :desc => "a setting")

        expect(setting.owner).to eq("root")
      end

      it "is unspecified when no specific owner is wanted" do
        expect(FileSetting.new(:settings => settings(), :desc => "a setting").owner).to be_nil
      end

      it "does not allow other owners" do
        expect { FileSetting.new(:settings => settings(), :desc => "a setting", :name => "testing", :default => "the default", :owner => "invalid") }.
          to raise_error(FileSetting::SettingError, /The :owner parameter for the setting 'testing' must be either 'root' or 'service'/)
      end
    end

    context "group" do
      it "is unspecified when no specific group is wanted" do
        setting = FileSetting.new(:settings => settings(), :desc => "a setting")

        expect(setting.group).to be_nil
      end

      it "is root if root is requested" do
        settings = settings(:group => "the_group")

        setting = FileSetting.new(:settings => settings, :group => "root", :desc => "a setting")

        expect(setting.group).to eq("root")
      end

      it "is the service group if we are making users" do
        settings = settings(:group => "the_service", :mkusers => true)

        setting = FileSetting.new(:settings => settings, :group => "service", :desc => "a setting")

        expect(setting.group).to eq("the_service")
      end

      it "is the service user if the group is available on the system" do
        settings = settings(:group => "the_service", :mkusers => false, :service_group_available? => true)

        setting = FileSetting.new(:settings => settings, :group => "service", :desc => "a setting")

        expect(setting.group).to eq("the_service")
      end

      it "is unspecified when the setting specifies service and the group is not available on the system" do
        settings = settings(:group => "the_service", :mkusers => false, :service_group_available? => false)

        setting = FileSetting.new(:settings => settings, :group => "service", :desc => "a setting")

        expect(setting.group).to be_nil
      end

      it "does not allow other groups" do
        expect { FileSetting.new(:settings => settings(), :group => "invalid", :name => 'testing', :desc => "a setting") }.
          to raise_error(FileSetting::SettingError, /The :group parameter for the setting 'testing' must be either 'root' or 'service'/)
      end
    end
  end

  it "should be able to be converted into a resource" do
    expect(FileSetting.new(:settings => double("settings"), :desc => "eh")).to respond_to(:to_resource)
  end

  describe "when being converted to a resource" do
    before do
      @basepath = make_absolute("/somepath")
      allow(Puppet::FileSystem).to receive(:exist?).and_call_original
      allow(Puppet::FileSystem).to receive(:exist?).with(@basepath).and_return(true)
      @settings = double('settings')
      @file = Puppet::Settings::FileSetting.new(:settings => @settings, :desc => "eh", :name => :myfile, :section => "mysect")
      allow(@settings).to receive(:value).with(:myfile, nil, false).and_return(@basepath)
    end

    it "should return :file as its type" do
      expect(@file.type).to eq(:file)
    end

    it "skips non-existent files" do
      expect(@file).to receive(:type).and_return(:file)
      expect(Puppet::FileSystem).to receive(:exist?).with(@basepath).and_return(false)
      expect(@file.to_resource).to be_nil
    end

    it "manages existing files" do
      expect(@file).to receive(:type).and_return(:file)
      expect(@file.to_resource).to be_instance_of(Puppet::Resource)
    end

    it "always manages directories" do
      expect(@file).to receive(:type).and_return(:directory)
      expect(@file.to_resource).to be_instance_of(Puppet::Resource)
    end

    describe "on POSIX systems", :if => Puppet.features.posix? do
      it "should skip files in /dev" do
        allow(@settings).to receive(:value).with(:myfile, nil, false).and_return("/dev/file")
        expect(@file.to_resource).to be_nil
      end
    end

    it "should skip files whose paths are not strings" do
      allow(@settings).to receive(:value).with(:myfile, nil, false).and_return(:foo)
      expect(@file.to_resource).to be_nil
    end

    it "should return a file resource with the path set appropriately" do
      resource = @file.to_resource
      expect(resource.type).to eq("File")
      expect(resource.title).to eq(@basepath)
    end

    it "should have a working directory with a root directory not called dev", :if => Puppet::Util::Platform.windows? do
      # Although C:\Dev\.... is a valid path on Windows, some other code may regard it as a path to be ignored.  e.g. /dev/null resolves to C:\dev\null on Windows.
      path = File.expand_path('somefile')
      expect(path).to_not match(/^[A-Z]:\/dev/i)
    end

    it "should fully qualified returned files if necessary (#795)" do
      allow(@settings).to receive(:value).with(:myfile, nil, false).and_return("myfile")
      path = File.expand_path('myfile')
      allow(Puppet::FileSystem).to receive(:exist?).with(path).and_return(true)
      expect(@file.to_resource.title).to eq(path)
    end

    it "should set the mode on the file if a mode is provided as an octal number" do
      Puppet[:manage_internal_file_permissions] = true
      @file.mode = 0755

      expect(@file.to_resource[:mode]).to eq('755')
    end

    it "should set the mode on the file if a mode is provided as a string" do
      Puppet[:manage_internal_file_permissions] = true
      @file.mode = '0755'

      expect(@file.to_resource[:mode]).to eq('755')
    end

    it "should not set the mode on a the file if manage_internal_file_permissions is disabled" do
      Puppet[:manage_internal_file_permissions] = false

      allow(@file).to receive(:mode).and_return(0755)

      expect(@file.to_resource[:mode]).to eq(nil)
    end

    it "should set the owner if running as root and the owner is provided" do
      Puppet[:manage_internal_file_permissions] = true
      expect(Puppet.features).to receive(:root?).and_return(true)
      allow(Puppet::Util::Platform).to receive(:windows?).and_return(false)
      allow(@file).to receive(:owner).and_return("foo")

      expect(@file.to_resource[:owner]).to eq("foo")
    end

    it "should not set the owner if manage_internal_file_permissions is disabled" do
      Puppet[:manage_internal_file_permissions] = false
      allow(Puppet.features).to receive(:root?).and_return(true)
      allow(@file).to receive(:owner).and_return("foo")

      expect(@file.to_resource[:owner]).to eq(nil)
    end

    it "should set the group if running as root and the group is provided" do
      Puppet[:manage_internal_file_permissions] = true
      expect(Puppet.features).to receive(:root?).and_return(true)
      allow(Puppet::Util::Platform).to receive(:windows?).and_return(false)
      allow(@file).to receive(:group).and_return("foo")

      expect(@file.to_resource[:group]).to eq("foo")
    end

    it "should not set the group if manage_internal_file_permissions is disabled" do
      Puppet[:manage_internal_file_permissions] = false
      allow(Puppet.features).to receive(:root?).and_return(true)
      allow(@file).to receive(:group).and_return("foo")

      expect(@file.to_resource[:group]).to eq(nil)
    end

    it "should not set owner if not running as root" do
      Puppet[:manage_internal_file_permissions] = true
      expect(Puppet.features).to receive(:root?).and_return(false)
      allow(Puppet::Util::Platform).to receive(:windows?).and_return(false)
      allow(@file).to receive(:owner).and_return("foo")

      expect(@file.to_resource[:owner]).to be_nil
    end

    it "should not set group if not running as root" do
      Puppet[:manage_internal_file_permissions] = true
      expect(Puppet.features).to receive(:root?).and_return(false)
      allow(Puppet::Util::Platform).to receive(:windows?).and_return(false)
      allow(@file).to receive(:group).and_return("foo")

      expect(@file.to_resource[:group]).to be_nil
    end

    describe "on Microsoft Windows systems" do
      before :each do
        allow(Puppet::Util::Platform).to receive(:windows?).and_return(true)
      end

      it "should not set owner" do
        allow(@file).to receive(:owner).and_return("foo")
        expect(@file.to_resource[:owner]).to be_nil
      end

      it "should not set group" do
        allow(@file).to receive(:group).and_return("foo")
        expect(@file.to_resource[:group]).to be_nil
      end
    end

    it "should set :ensure to the file type" do
      expect(@file).to receive(:type).and_return(:directory)
      expect(@file.to_resource[:ensure]).to eq(:directory)
    end

    it "should set the loglevel to :debug" do
      expect(@file.to_resource[:loglevel]).to eq(:debug)
    end

    it "should set the backup to false" do
      expect(@file.to_resource[:backup]).to be_falsey
    end

    it "should tag the resource with the settings section" do
      expect(@file).to receive(:section).and_return("mysect")
      expect(@file.to_resource).to be_tagged("mysect")
    end

    it "should tag the resource with the setting name" do
      expect(@file.to_resource).to be_tagged("myfile")
    end

    it "should tag the resource with 'settings'" do
      expect(@file.to_resource).to be_tagged("settings")
    end

    it "should set links to 'follow'" do
      expect(@file.to_resource[:links]).to eq(:follow)
    end
  end

  describe "#munge" do
    it 'does not expand the path of the special value :memory: so we can set dblocation to an in-memory database' do
      filesetting = FileSetting.new(:settings => double("settings"), :desc => "eh")
      expect(filesetting.munge(':memory:')).to eq(':memory:')
    end
  end

  context "when opening", :unless => Puppet::Util::Platform.windows? do
    let(:path) do
      tmpfile('file_setting_spec')
    end

    let(:setting) do
      settings = double("settings", :value => path)
      FileSetting.new(:name => :mysetting, :desc => "creates a file", :settings => settings)
    end

    it "creates a file with mode 0640" do
      setting.mode = '0640'

      expect(File).to_not be_exist(path)
      setting.open('w')

      expect(File).to be_exist(path)
      expect(Puppet::FileSystem.stat(path).mode & 0777).to eq(0640)
    end

    it "preserves the mode of an existing file" do
      setting.mode = '0640'

      Puppet::FileSystem.touch(path)
      Puppet::FileSystem.chmod(0644, path)
      setting.open('w')

      expect(Puppet::FileSystem.stat(path).mode & 0777).to eq(0644)
    end
  end
end
