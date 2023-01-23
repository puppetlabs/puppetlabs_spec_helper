require 'spec_helper'
require 'puppet_spec/files'
require 'puppet/pops'
require 'puppet/loaders'
require 'puppet_spec/compiler'

describe 'FileBased module loader' do
  include PuppetSpec::Files

  let(:static_loader) { Puppet::Pops::Loader::StaticLoader.new() }
  let(:loaders) { Puppet::Pops::Loaders.new(Puppet::Node::Environment.create(:testing, [])) }

  it 'can load a 4x function API ruby function in global name space' do
    module_dir = dir_containing('testmodule', {
      'lib' => {
        'puppet' => {
          'functions' => {
            'foo4x.rb' => <<-CODE
               Puppet::Functions.create_function(:foo4x) do
                 def foo4x()
                   'yay'
                 end
               end
            CODE
          }
            }
          }
        })

    module_loader = Puppet::Pops::Loader::ModuleLoaders.module_loader_from(static_loader, loaders, 'testmodule', module_dir)
    function = module_loader.load_typed(typed_name(:function, 'foo4x')).value

    expect(function.class.name).to eq('foo4x')
    expect(function.is_a?(Puppet::Functions::Function)).to eq(true)
  end

  it 'can load a 4x function API ruby function in qualified name space' do
    module_dir = dir_containing('testmodule', {
      'lib' => {
        'puppet' => {
          'functions' => {
            'testmodule' => {
              'foo4x.rb' => <<-CODE
                 Puppet::Functions.create_function('testmodule::foo4x') do
                   def foo4x()
                     'yay'
                   end
                 end
              CODE
              }
            }
          }
      }})

    module_loader = Puppet::Pops::Loader::ModuleLoaders.module_loader_from(static_loader, loaders, 'testmodule', module_dir)
    function = module_loader.load_typed(typed_name(:function, 'testmodule::foo4x')).value
    expect(function.class.name).to eq('testmodule::foo4x')
    expect(function.is_a?(Puppet::Functions::Function)).to eq(true)
  end

  it 'system loader has itself as private loader' do
    module_loader = loaders.puppet_system_loader
    expect(module_loader.private_loader).to be(module_loader)
  end

  it 'makes parent loader win over entries in child' do
    module_dir = dir_containing('testmodule', {
      'lib' => { 'puppet' => { 'functions' => { 'testmodule' => {
        'foo.rb' => <<-CODE
           Puppet::Functions.create_function('testmodule::foo') do
             def foo()
               'yay'
             end
           end
        CODE
      }}}}})
    module_loader = Puppet::Pops::Loader::ModuleLoaders.module_loader_from(static_loader, loaders, 'testmodule', module_dir)

    module_dir2 = dir_containing('testmodule2', {
      'lib' => { 'puppet' => { 'functions' => { 'testmodule2' => {
        'foo.rb' => <<-CODE
           raise "should not get here"
        CODE
      }}}}})
    module_loader2 = Puppet::Pops::Loader::ModuleLoaders::FileBased.new(module_loader, loaders, 'testmodule2', module_dir2, 'test2')

    function = module_loader2.load_typed(typed_name(:function, 'testmodule::foo')).value

    expect(function.class.name).to eq('testmodule::foo')
    expect(function.is_a?(Puppet::Functions::Function)).to eq(true)
  end

  context 'loading tasks' do
    before(:each) do
      Puppet[:tasks] = true
      Puppet.push_context(:loaders => loaders)
    end
    after(:each) { Puppet.pop_context }

    it 'can load tasks with multiple files' do
      module_dir = dir_containing('testmodule', 'tasks' => {'foo.py' => '', 'foo.json' => '{}'})

      module_loader = Puppet::Pops::Loader::ModuleLoaders.module_loader_from(static_loader, loaders, 'testmodule', module_dir)

      task = module_loader.load_typed(typed_name(:task, 'testmodule::foo')).value
      expect(task.name).to eq('testmodule::foo')
      expect(task.files.length).to eq(1)
      expect(task.files[0]['name']).to eq('foo.py')
    end

    it 'can load tasks with multiple implementations' do
      metadata = { 'implementations' => [{'name' => 'foo.py'}, {'name' => 'foo.ps1'}] }
      module_dir = dir_containing('testmodule', 'tasks' => {'foo.py' => '', 'foo.ps1' => '', 'foo.json' => metadata.to_json})

      module_loader = Puppet::Pops::Loader::ModuleLoaders.module_loader_from(static_loader, loaders, 'testmodule', module_dir)

      task = module_loader.load_typed(typed_name(:task, 'testmodule::foo')).value
      expect(task.name).to eq('testmodule::foo')
      expect(task.files.map {|impl| impl['name']}).to eq(['foo.py', 'foo.ps1'])
    end

    it 'can load multiple tasks with multiple files' do
      module_dir = dir_containing('testmodule', 'tasks' => {'foo.py' => '', 'foo.json' => '{}', 'foobar.py' => '', 'foobar.json' => '{}'})

      module_loader = Puppet::Pops::Loader::ModuleLoaders.module_loader_from(static_loader, loaders, 'testmodule', module_dir)

      foo_task = module_loader.load_typed(typed_name(:task, 'testmodule::foo')).value
      foobar_task = module_loader.load_typed(typed_name(:task, 'testmodule::foobar')).value

      expect(foo_task.name).to eq('testmodule::foo')
      expect(foo_task.files.length).to eq(1)
      expect(foo_task.files[0]['name']).to eq('foo.py')
      expect(foobar_task.name).to eq('testmodule::foobar')
      expect(foobar_task.files.length).to eq(1)
      expect(foobar_task.files[0]['name']).to eq('foobar.py')
    end

    it "won't load tasks with invalid names" do
      module_dir = dir_containing('testmodule', 'tasks' => {'a-b.py' => '', 'foo.tar.gz' => ''})

      module_loader = Puppet::Pops::Loader::ModuleLoaders.module_loader_from(static_loader, loaders, 'testmodule', module_dir)

      tasks = module_loader.discover(:task)
      expect(tasks).to be_empty

      expect(module_loader.load_typed(typed_name(:task, 'testmodule::foo'))).to be_nil
    end

    it "lists tasks without executables, if they specify implementations" do
      module_dir = dir_containing('testmodule', 'tasks' => {'foo.py' => '',
                                                            'bar.rb' => '',
                                                            'baz.json' => {'implementations' => ['name' => 'foo.py']}.to_json,
                                                            'qux.json' => '{}'})

      module_loader = Puppet::Pops::Loader::ModuleLoaders.module_loader_from(static_loader, loaders, 'testmodule', module_dir)

      tasks = module_loader.discover(:task)
      expect(tasks.length).to eq(3)
      expect(tasks.map(&:name).sort).to eq(['testmodule::bar', 'testmodule::baz', 'testmodule::foo'])

      expect(module_loader.load_typed(typed_name(:task, 'testmodule::foo'))).not_to be_nil
      expect(module_loader.load_typed(typed_name(:task, 'testmodule::bar'))).not_to be_nil
      expect(module_loader.load_typed(typed_name(:task, 'testmodule::baz'))).not_to be_nil
      expect { module_loader.load_typed(typed_name(:task, 'testmodule::qux')) }.to raise_error(/No source besides task metadata was found/)
    end

    it 'raises and error when `parameters` is not a hash' do
      metadata = { 'parameters' => 'foo' }
      module_dir = dir_containing('testmodule', 'tasks' => {'foo.py' => '', 'foo.json' => metadata.to_json})

      module_loader = Puppet::Pops::Loader::ModuleLoaders.module_loader_from(static_loader, loaders, 'testmodule', module_dir)
      expect{module_loader.load_typed(typed_name(:task, 'testmodule::foo'))}
        .to raise_error(Puppet::ParseError, /Failed to load metadata for task testmodule::foo: 'parameters' must be a hash/)
    end

    it 'raises and error when `implementations` `requirements` key is not an array' do
      metadata = { 'implementations' => { 'name' => 'foo.py', 'requirements' => 'foo'} }
      module_dir = dir_containing('testmodule', 'tasks' => {'foo.py' => '', 'foo.json' => metadata.to_json})

      module_loader = Puppet::Pops::Loader::ModuleLoaders.module_loader_from(static_loader, loaders, 'testmodule', module_dir)
      expect{module_loader.load_typed(typed_name(:task, 'testmodule::foo'))}
        .to raise_error(Puppet::Module::Task::InvalidMetadata,
        /Task metadata for task testmodule::foo does not specify implementations as an array/)
    end

    it 'raises and error when top-level `files` is not an array' do
      metadata = { 'files' => 'foo' }
      module_dir = dir_containing('testmodule', 'tasks' => {'foo.py' => '', 'foo.json' => metadata.to_json})

      module_loader = Puppet::Pops::Loader::ModuleLoaders.module_loader_from(static_loader, loaders, 'testmodule', module_dir)
      expect{module_loader.load_typed(typed_name(:task, 'testmodule::foo'))}
        .to raise_error(Puppet::Module::Task::InvalidMetadata, /The 'files' task metadata expects an array, got foo/)
    end

    it 'raises and error when `files` nested in `interpreters` is not an array' do
      metadata = { 'implementations' => [{'name' => 'foo.py', 'files' => 'foo'}] }
      module_dir = dir_containing('testmodule', 'tasks' => {'foo.py' => '', 'foo.json' => metadata.to_json})

      module_loader = Puppet::Pops::Loader::ModuleLoaders.module_loader_from(static_loader, loaders, 'testmodule', module_dir)
      expect{module_loader.load_typed(typed_name(:task, 'testmodule::foo'))}
        .to raise_error(Puppet::Module::Task::InvalidMetadata, /The 'files' task metadata expects an array, got foo/)
    end
  end

  def typed_name(type, name)
    Puppet::Pops::Loader::TypedName.new(type, name)
  end

  context 'module function and class using a module type alias' do
    include PuppetSpec::Compiler

    let(:modules) do
      {
        'mod' => {
          'functions' => {
            'afunc.pp' => <<-PUPPET.unindent
              function mod::afunc(Mod::Analias $v) {
                notice($v)
              }
          PUPPET
          },
          'types' => {
            'analias.pp' => <<-PUPPET.unindent
               type Mod::Analias = Enum[a,b]
               PUPPET
          },
          'manifests' => {
            'init.pp' => <<-PUPPET.unindent
              class mod(Mod::Analias $v) {
                notify { $v: }
              }
              PUPPET
          }
        }
      }
    end

    let(:testing_env) do
      {
        'testing' => {
          'modules' => modules
        }
      }
    end

    let(:environments_dir) { Puppet[:environmentpath] }

    let(:testing_env_dir) do
      dir_contained_in(environments_dir, testing_env)
      env_dir = File.join(environments_dir, 'testing')
      PuppetSpec::Files.record_tmp(env_dir)
      env_dir
    end

    let(:env) { Puppet::Node::Environment.create(:testing, [File.join(testing_env_dir, 'modules')]) }
    let(:node) { Puppet::Node.new('test', :environment => env) }

    # The call to mod:afunc will load the function, and as a consequence, make an attempt to load
    # the parameter type Mod::Analias. That load in turn, will trigger the Runtime3TypeLoader which
    # will load the manifests in Mod. The init.pp manifest also references the Mod::Analias parameter
    # which results in a recursive call to the same loader. This test asserts that this recursive
    # call is handled OK.
    # See PUP-7391 for more info.
    it 'should handle a recursive load' do
      expect(eval_and_collect_notices("mod::afunc('b')", node)).to eql(['b'])
    end
  end
end
