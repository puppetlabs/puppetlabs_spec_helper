require 'spec_helper'

require 'puppet/parser/type_loader'
require 'puppet/parser/parser_factory'
require 'puppet_spec/modules'
require 'puppet_spec/files'

describe Puppet::Parser::TypeLoader do
  include PuppetSpec::Modules
  include PuppetSpec::Files

  let(:empty_hostclass) { Puppet::Parser::AST::Hostclass.new('') }
  let(:loader) { Puppet::Parser::TypeLoader.new(:myenv) }
  let(:my_env) { Puppet::Node::Environment.create(:myenv, []) }

  around do |example|
    envs = Puppet::Environments::Static.new(my_env)

    Puppet.override(:environments => envs) do
      example.run
    end
  end

  it "should support an environment" do
    loader = Puppet::Parser::TypeLoader.new(:myenv)
    expect(loader.environment.name).to eq(:myenv)
  end

  it "should delegate its known resource types to its environment" do
    expect(loader.known_resource_types).to be_instance_of(Puppet::Resource::TypeCollection)
  end

  describe "when loading names from namespaces" do
    it "should do nothing if the name to import is an empty string" do
      expect(loader.try_load_fqname(:hostclass, "")).to be_nil
    end

    it "should attempt to import each generated name" do
      expect(loader).to receive(:import_from_modules).with("foo/bar").and_return([])
      expect(loader).to receive(:import_from_modules).with("foo").and_return([])
      loader.try_load_fqname(:hostclass, "foo::bar")
    end

    it "should attempt to load each possible name going from most to least specific" do
      ['foo/bar/baz', 'foo/bar', 'foo'].each do |path|
        expect(Puppet::Parser::Files).to receive(:find_manifests_in_modules).with(path, anything).and_return([nil, []]).ordered
      end

      loader.try_load_fqname(:hostclass, 'foo::bar::baz')
    end
  end

  describe "when importing" do
    let(:stub_parser) { double('Parser', :file= => nil, :parse => empty_hostclass) }

    before(:each) do
      allow(Puppet::Parser::ParserFactory).to receive(:parser).and_return(stub_parser)
    end

    it "should find all manifests matching the file or pattern" do
      expect(Puppet::Parser::Files).to receive(:find_manifests_in_modules).with("myfile", anything).and_return(["modname", %w{one}])
      loader.import("myfile", "/path")
    end

    it "should pass the environment when looking for files" do
      expect(Puppet::Parser::Files).to receive(:find_manifests_in_modules).with(anything, loader.environment).and_return(["modname", %w{one}])
      loader.import("myfile", "/path")
    end

    it "should fail if no files are found" do
      expect(Puppet::Parser::Files).to receive(:find_manifests_in_modules).and_return([nil, []])
      expect { loader.import("myfile", "/path") }.to raise_error(/No file\(s\) found for import/)
    end

    it "should parse each found file" do
      expect(Puppet::Parser::Files).to receive(:find_manifests_in_modules).and_return(["modname", [make_absolute("/one")]])
      expect(loader).to receive(:parse_file).with(make_absolute("/one")).and_return(Puppet::Parser::AST::Hostclass.new(''))
      loader.import("myfile", "/path")
    end

    it "should not attempt to import files that have already been imported" do
      loader = Puppet::Parser::TypeLoader.new(:myenv)

      expect(Puppet::Parser::Files).to receive(:find_manifests_in_modules).twice.and_return(["modname", %w{/one}])
      expect(loader.import("myfile", "/path")).not_to be_empty

      expect(loader.import("myfile", "/path")).to be_empty
    end
  end

  describe "when importing all" do
    let(:base) { tmpdir("base") }
    let(:modulebase1) { File.join(base, "first") }
    let(:modulebase2) { File.join(base, "second") }
    let(:my_env) { Puppet::Node::Environment.create(:myenv, [modulebase1, modulebase2]) }

    before do
      # Create two module path directories
      FileUtils.mkdir_p(modulebase1)
      FileUtils.mkdir_p(modulebase2)
    end

    def mk_module(basedir, name)
      PuppetSpec::Modules.create(name, basedir)
    end

    # We have to pass the base path so that we can
    # write to modules that are in the second search path
    def mk_manifests(base, mod, files)
      files.collect do |file|
        name = mod.name + "::" + file.gsub("/", "::")
        path = File.join(base, mod.name, "manifests", file + ".pp")
        FileUtils.mkdir_p(File.split(path)[0])

        # write out the class
        File.open(path, "w") { |f| f.print "class #{name} {}" }
        name
      end
    end

    it "should load all puppet manifests from all modules in the specified environment" do
      module1 = mk_module(modulebase1, "one")
      module2 = mk_module(modulebase2, "two")

      mk_manifests(modulebase1, module1, %w{a b})
      mk_manifests(modulebase2, module2, %w{c d})

      loader.import_all

      expect(loader.environment.known_resource_types.hostclass("one::a")).to be_instance_of(Puppet::Resource::Type)
      expect(loader.environment.known_resource_types.hostclass("one::b")).to be_instance_of(Puppet::Resource::Type)
      expect(loader.environment.known_resource_types.hostclass("two::c")).to be_instance_of(Puppet::Resource::Type)
      expect(loader.environment.known_resource_types.hostclass("two::d")).to be_instance_of(Puppet::Resource::Type)
    end

    it "should not load manifests from duplicate modules later in the module path" do
      module1 = mk_module(modulebase1, "one")

      # duplicate
      module2 = mk_module(modulebase2, "one")

      mk_manifests(modulebase1, module1, %w{a})
      mk_manifests(modulebase2, module2, %w{c})

      loader.import_all

      expect(loader.environment.known_resource_types.hostclass("one::c")).to be_nil
    end

    it "should load manifests from subdirectories" do
      module1 = mk_module(modulebase1, "one")

      mk_manifests(modulebase1, module1, %w{a a/b a/b/c})

      loader.import_all

      expect(loader.environment.known_resource_types.hostclass("one::a::b")).to be_instance_of(Puppet::Resource::Type)
      expect(loader.environment.known_resource_types.hostclass("one::a::b::c")).to be_instance_of(Puppet::Resource::Type)
    end

    it "should skip modules that don't have manifests" do
      mk_module(modulebase1, "one")
      module2 = mk_module(modulebase2, "two")
      mk_manifests(modulebase2, module2, %w{c d})

      loader.import_all

      expect(loader.environment.known_resource_types.hostclass("one::a")).to be_nil
      expect(loader.environment.known_resource_types.hostclass("two::c")).to be_instance_of(Puppet::Resource::Type)
      expect(loader.environment.known_resource_types.hostclass("two::d")).to be_instance_of(Puppet::Resource::Type)
    end
  end

  describe "when parsing a file" do
    it "requests a new parser instance for each file" do
      parser = double('Parser', :file= => nil, :parse => empty_hostclass)

      expect(Puppet::Parser::ParserFactory).to receive(:parser).twice.and_return(parser)

      loader.parse_file("/my/file")
      loader.parse_file("/my/other_file")
    end

    it "assigns the parser its file and then parses" do
      parser = double('parser')

      expect(Puppet::Parser::ParserFactory).to receive(:parser).and_return(parser)
      expect(parser).to receive(:file=).with("/my/file")
      expect(parser).to receive(:parse).and_return(empty_hostclass)

      loader.parse_file("/my/file")
    end
  end

  it "should be able to add classes to the current resource type collection" do
    file = tmpfile("simple_file.pp")
    File.open(file, "w") { |f| f.puts "class foo {}" }
    loader.import(File.basename(file), File.dirname(file))

    expect(loader.known_resource_types.hostclass("foo")).to be_instance_of(Puppet::Resource::Type)
  end
end
