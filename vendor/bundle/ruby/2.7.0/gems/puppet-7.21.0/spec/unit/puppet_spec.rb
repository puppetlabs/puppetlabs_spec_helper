require 'spec_helper'
require 'puppet'
require 'puppet_spec/files'

describe Puppet do
  include PuppetSpec::Files

  context "#version" do
    it "should be valid semver" do
      expect(SemanticPuppet::Version).to be_valid Puppet.version
    end
  end

  Puppet::Util::Log.eachlevel do |level|
    it "should have a method for sending '#{level}' logs" do
      expect(Puppet).to respond_to(level)
    end
  end

  it "should be able to change the path" do
    newpath = ENV["PATH"] + File::PATH_SEPARATOR + "/something/else"
    Puppet[:path] = newpath
    expect(ENV["PATH"]).to eq(newpath)
  end

  it 'should propagate --modulepath to base environment' do
    expect(Puppet::Node::Environment).to receive(:create).with(
      be_a(Symbol), ['/my/modules'], Puppet::Node::Environment::NO_MANIFEST)

    Puppet.base_context({
      :environmentpath => '/envs',
      :basemodulepath => '/base/modules',
      :modulepath => '/my/modules'
    })
  end

  it 'empty modulepath does not override basemodulepath' do
    expect(Puppet::Node::Environment).to receive(:create).with(
      be_a(Symbol), ['/base/modules'], Puppet::Node::Environment::NO_MANIFEST)

    Puppet.base_context({
      :environmentpath => '/envs',
      :basemodulepath => '/base/modules',
      :modulepath => ''
    })
  end

  it 'nil modulepath does not override basemodulepath' do
    expect(Puppet::Node::Environment).to receive(:create).with(
      be_a(Symbol), ['/base/modules'], Puppet::Node::Environment::NO_MANIFEST)

    Puppet.base_context({
      :environmentpath => '/envs',
      :basemodulepath => '/base/modules',
      :modulepath => nil
    })
  end

  context "Puppet::OLDEST_RECOMMENDED_RUBY_VERSION" do
    it "should have an oldest recommended ruby version constant" do
      expect(Puppet::OLDEST_RECOMMENDED_RUBY_VERSION).not_to be_nil
    end

    it "should be a string" do
      expect(Puppet::OLDEST_RECOMMENDED_RUBY_VERSION).to be_a_kind_of(String)
    end

    it "should match a semver version" do
      expect(SemanticPuppet::Version).to be_valid(Puppet::OLDEST_RECOMMENDED_RUBY_VERSION)
    end
  end

  context "Settings" do
    before(:each) do
      @old_settings = Puppet.settings
    end
    after(:each) do
      Puppet.replace_settings_object(@old_settings)
    end
    it "should allow for settings to be redefined with a custom object" do
      new_settings = double()
      Puppet.replace_settings_object(new_settings)
      expect(Puppet.settings).to eq(new_settings)
    end
  end

  context 'when registering implementations' do
    it 'does not register an implementation by default' do
      Puppet.initialize_settings

      expect(Puppet.runtime[:http]).to be_an_instance_of(Puppet::HTTP::Client)
    end

    it 'allows a http implementation to be registered' do
      http_impl = double('http')
      Puppet.initialize_settings([], true, true, http: http_impl)


      expect(Puppet.runtime[:http]).to eq(http_impl)
    end

    it 'allows a facter implementation to be registered' do
      facter_impl = double('facter')
      Puppet.initialize_settings([], true, true, facter: facter_impl)


      expect(Puppet.runtime[:facter]).to eq(facter_impl)
    end
  end

  context "initializing $LOAD_PATH" do
    it "should add libdir and module paths to the load path" do
      libdir = tmpdir('libdir_test')
      vendor_dir = tmpdir('vendor_modules')
      module_libdir = File.join(vendor_dir, 'amodule_core', 'lib')
      FileUtils.mkdir_p(module_libdir)

      Puppet[:libdir] = libdir
      Puppet[:vendormoduledir] = vendor_dir
      Puppet.initialize_settings

      expect($LOAD_PATH).to include(libdir)
      expect($LOAD_PATH).to include(module_libdir)
    end

  end
end
