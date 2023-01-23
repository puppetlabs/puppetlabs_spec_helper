require 'spec_helper'

describe "directory environments" do
  let(:args) { ['--configprint', 'modulepath', '--environment', 'direnv'] }
  let(:puppet) { Puppet::Application[:apply] }

  context "with a single directory environmentpath" do
    before(:each) do
      environmentdir = PuppetSpec::Files.tmpdir('envpath')
      Puppet[:environmentpath] = environmentdir
      FileUtils.mkdir_p(environmentdir + "/direnv/modules")
    end

    it "config prints the environments modulepath" do
      Puppet.settings.initialize_global_settings(args)
      expect {
        puppet.run
      }.to exit_with(0)
       .and output(%r{/direnv/modules}).to_stdout
    end

    it "config prints the cli --modulepath despite environment" do
      args << '--modulepath' << '/completely/different'
      Puppet.settings.initialize_global_settings(args)
      expect {
        puppet.run
      }.to exit_with(0)
       .and output(%r{/completely/different}).to_stdout
    end

    it 'given an 8.3 style path on Windows, will config print an expanded path',
      :if => Puppet::Util::Platform.windows? do

      # ensure an 8.3 style path is set for environmentpath
      shortened = Puppet::Util::Windows::File.get_short_pathname(Puppet[:environmentpath])
      expanded = Puppet::FileSystem.expand_path(shortened)

      Puppet[:environmentpath] = shortened
      expect(Puppet[:environmentpath]).to match(/~/)

      Puppet.settings.initialize_global_settings(args)
      expect {
        puppet.run
      }.to exit_with(0)
       .and output(a_string_matching(expanded)).to_stdout
    end
  end

  context "with an environmentpath having multiple directories" do
    let(:args) { ['--configprint', 'modulepath', '--environment', 'otherdirenv'] }

    before(:each) do
      envdir1 = File.join(Puppet[:confdir], 'env1')
      envdir2 = File.join(Puppet[:confdir], 'env2')
      Puppet[:environmentpath] = [envdir1, envdir2].join(File::PATH_SEPARATOR)
      FileUtils.mkdir_p(envdir2 + "/otherdirenv/modules")
    end

    it "config prints a directory environment modulepath" do
      Puppet.settings.initialize_global_settings(args)
      expect {
        puppet.run
      }.to exit_with(0)
       .and output(%r{otherdirenv/modules}).to_stdout
    end
  end
end
