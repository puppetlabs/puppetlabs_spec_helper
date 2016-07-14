
# This is a helper for the self-symlink entry of fixtures.yml
def source_dir
  Dir.pwd
end

# cache the repositories and retruns and hash object
def repositories
  unless @repositories
    @repositories = fixtures('repositories')
    @repositories.each do |remote, opts|
      if opts.instance_of?(String)
        @repositories[remote] = {"target" => opts} # inject a hash
      end
    end
  end
  @repositories
end

def fixtures(category)
  if File.exists?('.fixtures.yml')
    fixtures_yaml = '.fixtures.yml'
  elsif File.exists?('.fixtures.yaml')
    fixtures_yaml = '.fixtures.yaml'
  else
    fixtures_yaml = ''
  end

  begin
    fixtures = YAML.load_file(fixtures_yaml)["fixtures"]
  rescue Errno::ENOENT
    return {}
  rescue Psych::SyntaxError => e
    abort("Found malformed YAML in #{fixtures_yaml} on line #{e.line} column #{e.column}: #{e.problem}")
  end

  result = {}
  if fixtures.include? category and fixtures[category] != nil
    fixtures[category].each do |fixture, opts|
      if opts.instance_of?(String)
        source = opts
        target = "spec/fixtures/modules/#{fixture}"
        real_source = eval('"'+source+'"')
        result[real_source] = target
      elsif opts.instance_of?(Hash)
        target = "spec/fixtures/modules/#{fixture}"
        real_source = eval('"'+opts["repo"]+'"')
        result[real_source] = { "target" => target, "ref" => opts["ref"], "branch" => opts["branch"], "scm" => opts["scm"], "flags" => opts["flags"]}
      end
    end
  end
  return result
end

# creates a logger so we can log events with certain levels
def logger
  unless @logger
    require 'logger'
    if ENV['ENABLE_LOGGER']
       level = Logger::DEBUG
     else
       level = Logger::INFO
    end
    @logger = Logger.new(STDOUT)
    @logger.level = level
  end
  @logger
end

def clone_repo(scm, remote, target, ref=nil, branch=nil, flags = nil)
  args = []
  case scm
  when 'hg'
    args.push('clone')
    args.push('-u', ref) if ref
    args.push(flags) if flags
    args.push(remote, target)
  when 'git'
    args.push('clone')
    args.push('--depth 1') unless ref
    args.push('-b', branch) if branch
    args.push(flags) if flags
    args.push(remote, target)
  else
    fail "Unfortunately #{scm} is not supported yet"
  end
  result = system("#{scm} #{args.flatten.join ' '}")
  unless File::exists?(target)
    fail "Failed to clone #{scm} repository #{remote} into #{target}"
  end
  result
end

def revision(scm, target, ref)
  args = []
  case scm
  when 'hg'
    args.push('update', 'clean', '-r', ref)
  when 'git'
    args.push('reset', '--hard', ref)
  else
    fail "Unfortunately #{scm} is not supported yet"
  end
  system("cd #{target} && #{scm} #{args.flatten.join ' '}")
end

# returns the current thread count that is currently active
# a status of false or nil means the thread completed
# so when anything else we count that as a active thread
def current_thread_count(items)
  active_threads = items.find_all do |item, opts|
    if opts[:thread]
      opts[:thread].status
    else
      false
    end
  end
  logger.debug "Current thread count #{active_threads.count}"
  active_threads.count
end

# returns the max_thread_count
# because we may want to limit ssh or https connections
def max_thread_limit
  unless @max_thread_limit
    # the default thread count is 10 but can be
    # raised by using environment variable MAX_FIXTURE_THREAD_COUNT
    if ENV['MAX_FIXTURE_THREAD_COUNT'].to_i > 0
      @max_thread_limit = ENV['MAX_FIXTURE_THREAD_COUNT'].to_i
    else
      @max_thread_limit = 10 # the default
    end
  end
  @max_thread_limit
end

desc "Create the fixtures directory"
task :spec_prep do
  # Ruby only sets File::ALT_SEPARATOR on Windows and Rubys standard library
  # uses this to check for Windows
  is_windows = !!File::ALT_SEPARATOR
  puppet_symlink_available = false
  begin
    require 'puppet'
    puppet_symlink_available = Puppet::FileSystem.respond_to?(:symlink)
  rescue
  end

  # git has a race condition creating that directory, that would lead to aborted clone operations
  FileUtils::mkdir_p("spec/fixtures/modules")

  repositories.each do |remote, opts|
    scm = 'git'
    target = opts["target"]
    ref = opts["ref"]
    scm = opts["scm"] if opts["scm"]
    branch = opts["branch"] if opts["branch"]
    flags = opts["flags"]
    # get the current active threads that are alive
    count = current_thread_count(repositories)
    if count < max_thread_limit
      logger.debug "New Thread started for #{remote}"
      # start up a new thread and store it in the opts hash
      opts[:thread] = Thread.new do
        clone_repo(scm, remote, target, ref, branch, flags)
        revision(scm, target, ref) if ref
      end
    else
      # the last thread started should be the longest wait
      item, item_opts = repositories.find_all {|i,o| o.has_key?(:thread)}.last
      logger.debug "Waiting on #{item}"
      item_opts[:thread].join  # wait for the thread to finish
      # now that we waited lets try again
      redo
    end
  end

  # wait for all the threads to finish
  repositories.each {|remote, opts| opts[:thread].join }

  fixtures("symlinks").each do |source, target|
    if is_windows
      fail "Cannot symlink on Windows unless using at least Puppet 3.5" if !puppet_symlink_available
      Puppet::FileSystem::exist?(target) || Puppet::FileSystem::symlink(source, target)
    else
      File::exists?(target) || FileUtils::ln_sf(source, target)
    end
  end

  fixtures("forge_modules").each do |remote, opts|
    ref = ""
    flags = ""
    if opts.instance_of?(String)
      target = opts
    elsif opts.instance_of?(Hash)
      target = opts["target"]
      ref = " --version #{opts['ref']}" if not opts['ref'].nil?
      flags = " #{opts['flags']}" if opts['flags']
    end
    next if File::exists?(target)

    command = "puppet module install" + ref + flags + \
      " --ignore-dependencies" \
      " --force" \
      " --module_working_dir spec/fixtures/module-working-dir" \
      " --target-dir spec/fixtures/modules #{remote}"

    unless system(command)
      fail "Failed to install module #{remote} to #{target}"
    end
  end

  FileUtils::mkdir_p("spec/fixtures/manifests")
  FileUtils::touch("spec/fixtures/manifests/site.pp")
end

desc "Clean up the fixtures directory"
task :spec_clean do
  fixtures("repositories").each do |remote, opts|
    if opts.instance_of?(String)
      target = opts
    elsif opts.instance_of?(Hash)
      target = opts["target"]
    end
    FileUtils::rm_rf(target)
  end

  fixtures("forge_modules").each do |remote, opts|
    if opts.instance_of?(String)
      target = opts
    elsif opts.instance_of?(Hash)
      target = opts["target"]
    end
    FileUtils::rm_rf(target)
  end

  FileUtils::rm_rf("spec/fixtures/module-working-dir")

  fixtures("symlinks").each do |source, target|
    FileUtils::rm_f(target)
  end

  if File.zero?("spec/fixtures/manifests/site.pp")
    FileUtils::rm_f("spec/fixtures/manifests/site.pp")
  end

end
