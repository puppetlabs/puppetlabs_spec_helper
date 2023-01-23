module PuppetSpec::Settings

  # It would probably be preferable to refactor defaults.rb such that the real definitions of
  #  these settings were available as a variable, which was then accessible for use during tests.
  #  However, I'm not doing that yet because I don't want to introduce any additional moving parts
  #  to this already very large changeset.
  #  Would be nice to clean this up later.  --cprice 2012-03-20
  TEST_APP_DEFAULT_DEFINITIONS = {
    :name         => { :default => "test", :desc => "name" },
    :logdir       => { :type => :directory, :default => "test", :desc => "logdir" },
    :confdir      => { :type => :directory, :default => "test", :desc => "confdir" },
    :codedir      => { :type => :directory, :default => "test", :desc => "codedir" },
    :vardir       => { :type => :directory, :default => "test", :desc => "vardir" },
    :publicdir    => { :type => :directory, :default => "test", :desc => "publicdir" },
    :rundir       => { :type => :directory, :default => "test", :desc => "rundir" },
  }.freeze

  TEST_APP_DEFAULT_VALUES = TEST_APP_DEFAULT_DEFINITIONS.inject({}) do |memo, (key, value)|
    memo[key] = value[:default]
    memo
  end.freeze

  def set_puppet_conf(confdir, settings)
    FileUtils.mkdir_p(confdir)
    write_file(File.join(confdir, "puppet.conf"), settings)
  end

  def set_environment_conf(environmentpath, environment, settings)
    envdir = File.join(environmentpath, environment)
    FileUtils.mkdir_p(envdir)
    write_file(File.join(envdir, 'environment.conf'), settings)
  end

  def write_file(file, contents)
    File.open(file, "w") do |f|
      f.puts(contents)
    end
  end
end
