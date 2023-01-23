require 'spec_helper'
require 'puppet_spec/compiler'

require 'puppet/transaction'

Puppet::Type.newtype(:devicetype) do
  apply_to_device
  newparam(:name)
end

describe Puppet::Transaction do
  include PuppetSpec::Files
  include PuppetSpec::Compiler

  before do
    allow(Puppet::Util::Storage).to receive(:store)
  end

  def mk_catalog(*resources)
    catalog = Puppet::Resource::Catalog.new(Puppet::Node.new("mynode"))
    resources.each { |res| catalog.add_resource res }
    catalog
  end

  def touch_path
    Puppet.features.microsoft_windows? ? "#{ENV['windir']}\\system32" : "/usr/bin:/bin"
  end

  def usr_bin_touch(path)
    Puppet.features.microsoft_windows? ? "#{ENV['windir']}\\system32\\cmd.exe /c \"type NUL >> \"#{path}\"\"" : "/usr/bin/touch #{path}"
  end

  def touch(path)
    Puppet.features.microsoft_windows? ? "cmd.exe /c \"type NUL >> \"#{path}\"\"" : "touch #{path}"
  end

  it "should not apply generated resources if the parent resource fails" do
    catalog = Puppet::Resource::Catalog.new
    resource = Puppet::Type.type(:file).new :path => make_absolute("/foo/bar"), :backup => false
    catalog.add_resource resource

    child_resource = Puppet::Type.type(:file).new :path => make_absolute("/foo/bar/baz"), :backup => false

    expect(resource).to receive(:eval_generate).and_return([child_resource])

    transaction = Puppet::Transaction.new(catalog, nil, Puppet::Graph::SequentialPrioritizer.new)

    expect(resource).to receive(:retrieve).and_raise("this is a failure")
    allow(resource).to receive(:err)

    expect(child_resource).not_to receive(:retrieve)

    transaction.evaluate
  end

  it "should not apply virtual resources" do
    catalog = Puppet::Resource::Catalog.new
    resource = Puppet::Type.type(:file).new :path => make_absolute("/foo/bar"), :backup => false
    resource.virtual = true
    catalog.add_resource resource

    transaction = Puppet::Transaction.new(catalog, nil, Puppet::Graph::SequentialPrioritizer.new)

    expect(resource).not_to receive(:retrieve)

    transaction.evaluate
  end

  it "should apply exported resources" do
    catalog = Puppet::Resource::Catalog.new
    path = tmpfile("exported_files")
    resource = Puppet::Type.type(:file).new :path => path, :backup => false, :ensure => :file
    resource.exported = true
    catalog.add_resource resource

    catalog.apply
    expect(Puppet::FileSystem.exist?(path)).to be_truthy
  end

  it "should not apply virtual exported resources" do
    catalog = Puppet::Resource::Catalog.new
    resource = Puppet::Type.type(:file).new :path => make_absolute("/foo/bar"), :backup => false
    resource.exported = true
    resource.virtual = true
    catalog.add_resource resource

    transaction = Puppet::Transaction.new(catalog, nil, Puppet::Graph::SequentialPrioritizer.new)

    expect(resource).not_to receive(:retrieve)

    transaction.evaluate
  end

  it "should not apply device resources on normal host" do
    catalog = Puppet::Resource::Catalog.new
    resource = Puppet::Type.type(:devicetype).new :name => "FastEthernet 0/1"
    catalog.add_resource resource

    transaction = Puppet::Transaction.new(catalog, nil, Puppet::Graph::SequentialPrioritizer.new)
    transaction.for_network_device = false

    expect(transaction).not_to receive(:apply).with(resource, nil)

    transaction.evaluate
    expect(transaction.resource_status(resource)).to be_skipped
  end

  it "should not apply host resources on device" do
    catalog = Puppet::Resource::Catalog.new
    resource = Puppet::Type.type(:file).new :path => make_absolute("/foo/bar"), :backup => false
    catalog.add_resource resource

    transaction = Puppet::Transaction.new(catalog, nil, Puppet::Graph::SequentialPrioritizer.new)
    transaction.for_network_device = true

    expect(transaction).not_to receive(:apply).with(resource, nil)

    transaction.evaluate
    expect(transaction.resource_status(resource)).to be_skipped
  end

  it "should apply device resources on device" do
    catalog = Puppet::Resource::Catalog.new
    resource = Puppet::Type.type(:devicetype).new :name => "FastEthernet 0/1"
    catalog.add_resource resource

    transaction = Puppet::Transaction.new(catalog, nil, Puppet::Graph::SequentialPrioritizer.new)
    transaction.for_network_device = true

    expect(transaction).to receive(:apply).with(resource, nil)

    transaction.evaluate
    expect(transaction.resource_status(resource)).not_to be_skipped
  end

  it "should apply resources appliable on host and device on a device" do
    catalog = Puppet::Resource::Catalog.new
    resource = Puppet::Type.type(:schedule).new :name => "test"
    catalog.add_resource resource

    transaction = Puppet::Transaction.new(catalog, nil, Puppet::Graph::SequentialPrioritizer.new)
    transaction.for_network_device = true

    expect(transaction).to receive(:apply).with(resource, nil)

    transaction.evaluate
    expect(transaction.resource_status(resource)).not_to be_skipped
  end

  # Verify that one component requiring another causes the contained
  # resources in the requiring component to get refreshed.
  it "should propagate events from a contained resource through its container to its dependent container's contained resources" do
    file = Puppet::Type.type(:file).new :path => tmpfile("event_propagation"), :ensure => :present
    execfile = File.join(tmpdir("exec_event"), "exectestingness2")
    exec = Puppet::Type.type(:exec).new :command => touch(execfile), :path => ENV['PATH']
    catalog = mk_catalog(file)

    fcomp = Puppet::Type.type(:component).new(:name => "Foo[file]")
    catalog.add_resource fcomp
    catalog.add_edge(fcomp, file)

    ecomp = Puppet::Type.type(:component).new(:name => "Foo[exec]")
    catalog.add_resource ecomp
    catalog.add_resource exec
    catalog.add_edge(ecomp, exec)

    ecomp[:subscribe] = Puppet::Resource.new(:foo, "file")
    exec[:refreshonly] = true

    expect(exec).to receive(:refresh)
    catalog.apply
  end

  # Make sure that multiple subscriptions get triggered.
  it "should propagate events to all dependent resources", :unless => RUBY_PLATFORM == 'java' do
    path = tmpfile("path")
    file1 = tmpfile("file1")
    file2 = tmpfile("file2")

    file = Puppet::Type.type(:file).new(
      :path   => path,
      :ensure => "file"
    )

    exec1 = Puppet::Type.type(:exec).new(
      :path    => ENV["PATH"],
      :command => touch(file1),
      :refreshonly => true,
      :subscribe   => Puppet::Resource.new(:file, path)
    )

    exec2 = Puppet::Type.type(:exec).new(
      :path        => ENV["PATH"],
      :command     => touch(file2),
      :refreshonly => true,
      :subscribe   => Puppet::Resource.new(:file, path)
    )

    catalog = mk_catalog(file, exec1, exec2)
    catalog.apply
    expect(Puppet::FileSystem.exist?(file1)).to be_truthy
    expect(Puppet::FileSystem.exist?(file2)).to be_truthy
  end

  it "does not refresh resources that have 'noop => true'" do
    path = tmpfile("path")

    notify = Puppet::Type.type(:notify).new(
      :name    => "trigger",
      :notify  => Puppet::Resource.new(:exec, "noop exec")
    )

    noop_exec = Puppet::Type.type(:exec).new(
      :name    => "noop exec",
      :path    => ENV["PATH"],
      :command => touch(path),
      :noop    => true
    )

    catalog = mk_catalog(notify, noop_exec)
    catalog.apply
    expect(Puppet::FileSystem.exist?(path)).to be_falsey
  end

  it "should apply no resources whatsoever if a pre_run_check fails" do
    path = tmpfile("path")
    file = Puppet::Type.type(:file).new(
      :path => path,
      :ensure => "file"
    )
    notify = Puppet::Type.type(:notify).new(
      :title => "foo"
    )
    expect(notify).to receive(:pre_run_check).and_raise(Puppet::Error, "fail for testing")

    catalog = mk_catalog(file, notify)
    expect { catalog.apply }.to raise_error(Puppet::Error, /Some pre-run checks failed/)
    expect(Puppet::FileSystem.exist?(path)).not_to be_truthy
  end

  it "one failed refresh should propagate its failure to dependent refreshes", :unless => RUBY_PLATFORM == 'java' do
    path = tmpfile("path")
    newfile = tmpfile("file")
      file = Puppet::Type.type(:file).new(
      :path => path,
      :ensure => "file"
    )

    exec1 = Puppet::Type.type(:exec).new(
      :path => ENV["PATH"],
      :command => touch(File.expand_path("/this/cannot/possibly/exist")),
      :logoutput => true,
      :refreshonly => true,
      :subscribe => file,
      :title => "one"
    )

    exec2 = Puppet::Type.type(:exec).new(
      :path => ENV["PATH"],
      :command => touch(newfile),
      :logoutput => true,
      :refreshonly => true,
      :subscribe => [file, exec1],
      :title => "two"
    )

    allow(exec1).to receive(:err)

    catalog = mk_catalog(file, exec1, exec2)
    catalog.apply
    expect(Puppet::FileSystem.exist?(newfile)).to be_falsey
  end

  # Ensure when resources have been generated with eval_generate that event
  # propagation still works when filtering with tags
  context "when filtering with tags", :unless => RUBY_PLATFORM == 'java' do
    context "when resources are dependent on dynamically generated resources" do
      it "should trigger (only) appropriately tagged dependent resources" do
        source = dir_containing('sourcedir', {'foo' => 'bar'})
        target = tmpdir('targetdir')
        file1 = tmpfile("file1")
        file2 = tmpfile("file2")

        file = Puppet::Type.type(:file).new(
          :path    => target,
          :source  => source,
          :ensure  => :present,
          :recurse => true,
          :tag     => "foo_tag",
        )

        exec1 = Puppet::Type.type(:exec).new(
          :path        => ENV["PATH"],
          :command     => touch(file1),
          :refreshonly => true,
          :subscribe   => file,
          :tag         => "foo_tag",
        )

        exec2 = Puppet::Type.type(:exec).new(
          :path        => ENV["PATH"],
          :command     => touch(file2),
          :refreshonly => true,
          :subscribe   => file,
        )

        Puppet[:tags] = "foo_tag"
        catalog = mk_catalog(file, exec1, exec2)
        catalog.apply
        expect(Puppet::FileSystem.exist?(file1)).to be_truthy
        expect(Puppet::FileSystem.exist?(file2)).to be_falsey
      end

      it "should trigger implicitly tagged dependent resources, ie via type name" do
        file1 = tmpfile("file1")
        file2 = tmpfile("file2")

        expect(Puppet::FileSystem).to_not be_exist(file2)

        exec1 = Puppet::Type.type(:exec).new(
          :name        => "exec1",
          :path        => ENV["PATH"],
          :command     => touch(file1),
        )

        exec2 = Puppet::Type.type(:exec).new(
          :name        => "exec2",
          :path        => ENV["PATH"],
          :command     => touch(file2),
          :refreshonly => true,
          :subscribe   => exec1,
        )

        Puppet[:tags] = "exec"
        catalog = mk_catalog(exec1, exec2)
        catalog.apply
        expect(Puppet::FileSystem.exist?(file1)).to be_truthy
        expect(Puppet::FileSystem.exist?(file2)).to be_truthy
      end
    end

    it "should propagate events correctly from a tagged container when running with tags" do
      file1 = tmpfile("original_tag")
      file2 = tmpfile("tag_propagation")
      command1 = usr_bin_touch(file1)
      command2 = usr_bin_touch(file2)
      manifest = <<-"MANIFEST"
        class foo {
          exec { 'notify test':
            command     => '#{command1}',
            refreshonly => true,
          }
        }

        class test {
          include foo

          exec { 'test':
            command => '#{command2}',
            notify  => Class['foo'],
          }
        }

        include test
      MANIFEST

      Puppet[:tags] = 'test'
      apply_compiled_manifest(manifest)
      expect(Puppet::FileSystem.exist?(file1)).to be_truthy
      expect(Puppet::FileSystem.exist?(file2)).to be_truthy
    end
  end

  describe "skipping resources" do
    let(:fname) { tmpfile("exec") }

    let(:file) do
      Puppet::Type.type(:file).new(
        :name => tmpfile("file"),
        :ensure => "file",
        :backup => false
      )
    end

    let(:exec) do
      Puppet::Type.type(:exec).new(
        :name => touch(fname),
        :path => touch_path,
        :subscribe => Puppet::Resource.new("file", file.name)
      )
    end

    it "does not trigger unscheduled resources", :unless => RUBY_PLATFORM == 'java' do
      catalog = mk_catalog
      catalog.add_resource(*Puppet::Type.type(:schedule).mkdefaultschedules)

      Puppet[:ignoreschedules] = false

      exec[:schedule] = "monthly"

      catalog.add_resource(file, exec)

      # Run it once so further runs don't schedule the resource
      catalog.apply
      expect(Puppet::FileSystem.exist?(fname)).to be_truthy

      # Now remove it, so it can get created again
      Puppet::FileSystem.unlink(fname)

      file[:content] = "some content"

      catalog.apply
      expect(Puppet::FileSystem.exist?(fname)).to be_falsey
    end

    it "does not trigger untagged resources" do
      catalog = mk_catalog

      Puppet[:tags] = "runonly"
      file.tag("runonly")

      catalog.add_resource(file, exec)
      catalog.apply
      expect(Puppet::FileSystem.exist?(fname)).to be_falsey
    end

    it "does not trigger skip-tagged resources" do
      catalog = mk_catalog

      Puppet[:skip_tags] = "skipme"
      exec.tag("skipme")

      catalog.add_resource(file, exec)
      catalog.apply
      expect(Puppet::FileSystem.exist?(fname)).to be_falsey
    end

    it "does not trigger resources with failed dependencies" do
      catalog = mk_catalog
      file[:path] = make_absolute("/foo/bar/baz")

      catalog.add_resource(file, exec)
      catalog.apply

      expect(Puppet::FileSystem.exist?(fname)).to be_falsey
    end
  end

  it "should not attempt to evaluate resources with failed dependencies", :unless => RUBY_PLATFORM == 'java' do

    exec = Puppet::Type.type(:exec).new(
      :command => "#{File.expand_path('/bin/mkdir')} /this/path/cannot/possibly/exist",
      :title => "mkdir"
    )

    file1 = Puppet::Type.type(:file).new(
      :title => "file1",
      :path => tmpfile("file1"),
      :require => exec,
      :ensure => :file
    )

    file2 = Puppet::Type.type(:file).new(
      :title => "file2",
      :path => tmpfile("file2"),
      :require => file1,
      :ensure => :file
    )

    catalog = mk_catalog(exec, file1, file2)
    transaction = catalog.apply

    expect(Puppet::FileSystem.exist?(file1[:path])).to be_falsey
    expect(Puppet::FileSystem.exist?(file2[:path])).to be_falsey

    expect(transaction.resource_status(file1).skipped).to be_truthy
    expect(transaction.resource_status(file2).skipped).to be_truthy

    expect(transaction.resource_status(file1).failed_dependencies).to eq([exec])
    expect(transaction.resource_status(file2).failed_dependencies).to eq([exec])
  end

  it "on failure, skips dynamically-generated dependents", :unless => RUBY_PLATFORM == 'java' do
    exec = Puppet::Type.type(:exec).new(
      :command => "#{File.expand_path('/bin/mkdir')} /this/path/cannot/possibly/exist",
      :title => "mkdir"
    )

    tmp = tmpfile("dir1")
    FileUtils.mkdir_p(tmp)
    FileUtils.mkdir_p(File.join(tmp, "foo"))

    purge_dir = Puppet::Type.type(:file).new(
      :title => "dir1",
      :path => tmp,
      :require => exec,
      :ensure => :directory,
      :recurse => true,
      :purge => true
    )

    catalog = mk_catalog(exec, purge_dir)
    txn = catalog.apply

    expect(txn.resource_status(purge_dir).skipped).to be_truthy

    children = catalog.relationship_graph.direct_dependents_of(purge_dir)

    children.each do |child|
      expect(txn.resource_status(child).skipped).to be_truthy
    end

    expect(Puppet::FileSystem.exist?(File.join(tmp, "foo"))).to be_truthy
  end

  it "should not trigger subscribing resources on failure", :unless => RUBY_PLATFORM == 'java' do
    file1 = tmpfile("file1")
    file2 = tmpfile("file2")

    create_file1 = Puppet::Type.type(:exec).new(
      :command => usr_bin_touch(file1)
    )

    exec = Puppet::Type.type(:exec).new(
      :command => "#{File.expand_path('/bin/mkdir')} /this/path/cannot/possibly/exist",
      :title => "mkdir",
      :notify => create_file1
    )

    create_file2 = Puppet::Type.type(:exec).new(
      :command => usr_bin_touch(file2),
      :subscribe => exec
    )

    catalog = mk_catalog(exec, create_file1, create_file2)
    catalog.apply

    expect(Puppet::FileSystem.exist?(file1)).to be_falsey
    expect(Puppet::FileSystem.exist?(file2)).to be_falsey
  end

  # #801 -- resources only checked in noop should be rescheduled immediately.
  it "should immediately reschedule noop resources" do
    Puppet::Type.type(:schedule).mkdefaultschedules
    resource = Puppet::Type.type(:notify).new(:name => "mymessage", :noop => true)
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource resource

    trans = catalog.apply

    expect(trans.resource_harness).to be_scheduled(resource)
  end
end
