require 'yaml'
require 'open3'

module PuppetlabsSpecHelper; end
module PuppetlabsSpecHelper::Tasks; end
module PuppetlabsSpecHelper::Tasks::FixtureHelpers
  # This is a helper for the self-symlink entry of fixtures.yml
  def source_dir
    Dir.pwd
  end

  # cache the repositories and return a hash object
  def repositories
    unless @repositories
      @repositories = fixtures('repositories')
    end
    @repositories
  end

  def auto_symlink
    { File.basename(Dir.pwd).split('-').last => '#{source_dir}' }
  end

  def fixtures(category)
    fixtures_yaml = if ENV['FIXTURES_YML']
                      ENV['FIXTURES_YML']
                    elsif File.exist?('.fixtures.yml')
                      '.fixtures.yml'
                    elsif File.exist?('.fixtures.yaml')
                      '.fixtures.yaml'
                    else
                      false
                    end

    begin
      fixtures = if fixtures_yaml
                   YAML.load_file(fixtures_yaml) || { 'fixtures' => {} }
                 else
                   { 'fixtures' => {} }
                 end
    rescue Errno::ENOENT
      raise("Fixtures file not found: '#{fixtures_yaml}'")
    rescue Psych::SyntaxError => e
      raise("Found malformed YAML in '#{fixtures_yaml}' on line #{e.line} column #{e.column}: #{e.problem}")
    end

    unless fixtures.include?('fixtures')
      # File is non-empty, but does not specify fixtures
      raise("No 'fixtures' entries found in '#{fixtures_yaml}'; required")
    end

    fixture_defaults = if fixtures.include? 'defaults'
                         fixtures['defaults']
                       else
                         {}
                       end

    fixtures = fixtures['fixtures']

    if fixtures['symlinks'].nil?
      fixtures['symlinks'] = auto_symlink
    end

    result = {}
    if fixtures.include?(category) && !fixtures[category].nil?

      defaults = { 'target' => 'spec/fixtures/modules' }

      # load defaults from the `.fixtures.yml` `defaults` section
      # for the requested category and merge them into my defaults
      if fixture_defaults.include? category
        defaults = defaults.merge(fixture_defaults[category])
      end

      fixtures[category].each do |fixture, opts|
        # convert a simple string fixture to a hash, by
        # using the string fixture as the `repo` option of the hash.
        if opts.instance_of?(String)
          opts = { 'repo' => opts }
        end
        # there should be a warning or something if it's not a hash...
        next unless opts.instance_of?(Hash)
        # merge our options into the defaults to get the
        # final option list
        opts = defaults.merge(opts)

        real_target = eval('"' + opts['target'] + '"')
        real_source = eval('"' + opts['repo'] + '"')

        result[real_source] = {
          'target' => File.join(real_target, fixture),
          'ref' => opts['ref'],
          'branch' => opts['branch'],
          'scm' => opts['scm'],
          'flags' => opts['flags'],
          'subdir' => opts['subdir'],
        }
      end
    end
    result
  end

  def clone_repo(scm, remote, target, _subdir = nil, ref = nil, branch = nil, flags = nil)
    args = []
    case scm
    when 'hg'
      args.push('clone')
      args.push('-b', branch) if branch
      args.push(flags) if flags
      args.push(remote, target)
    when 'git'
      args.push('clone')
      args.push('--depth 1') unless ref
      args.push('-b', branch) if branch
      args.push(flags) if flags
      args.push(remote, target)
    else
      raise "Unfortunately #{scm} is not supported yet"
    end
    result = system("#{scm} #{args.flatten.join ' '}")
    unless File.exist?(target)
      raise "Failed to clone #{scm} repository #{remote} into #{target}"
    end
    result
  end

  def update_repo(scm, target)
    args = case scm
           when 'hg'
             ['pull']
           when 'git'
             ['fetch'].tap do |git_args|
               git_args << '--unshallow' if shallow_git_repo?
             end
           else
             raise "Unfortunately #{scm} is not supported yet"
           end
    system("#{scm} #{args.flatten.join(' ')}", chdir: target)
  end

  def shallow_git_repo?
    File.file?(File.join('.git', 'shallow'))
  end

  def revision(scm, target, ref)
    args = []
    case scm
    when 'hg'
      args.push('update', '--clean', '-r', ref)
    when 'git'
      args.push('reset', '--hard', ref)
    else
      raise "Unfortunately #{scm} is not supported yet"
    end
    system("#{scm} #{args.flatten.join ' '}", chdir: target)
  end

  def valid_repo?(scm, target, remote)
    return false unless File.directory?(target)
    return true if scm == 'hg'

    return true if git_remote_url(target) == remote

    warn "Git remote for #{target} has changed, recloning repository"
    FileUtils.rm_rf(target)
    false
  end

  def git_remote_url(target)
    output, status = Open3.capture2e('git', '-C', target, 'remote', 'get-url', 'origin')
    status.success? ? output.strip : nil
  end

  def remove_subdirectory(target, subdir)
    unless subdir.nil?
      Dir.mktmpdir do |tmpdir|
        FileUtils.mv(Dir.glob("#{target}/#{subdir}/{.[^\.]*,*}"), tmpdir)
        FileUtils.rm_rf("#{target}/#{subdir}")
        FileUtils.mv(Dir.glob("#{tmpdir}/{.[^\.]*,*}"), target.to_s)
      end
    end
  end

  # creates a logger so we can log events with certain levels
  def logger
    unless @logger
      require 'logger'
      level = if ENV['ENABLE_LOGGER']
                Logger::DEBUG
              else
                Logger::INFO
              end
      @logger = Logger.new(STDERR)
      @logger.level = level
    end
    @logger
  end

  def module_working_directory
    # The problem with the relative path is that PMT doesn't expand the path properly and so passing in a relative path here
    # becomes something like C:\somewhere\backslashes/spec/fixtures/work-dir on Windows, and then PMT barfs itself.
    # This has been reported as https://tickets.puppetlabs.com/browse/PUP-4884
    File.expand_path((ENV['MODULE_WORKING_DIR']) ? ENV['MODULE_WORKING_DIR'] : 'spec/fixtures/work-dir')
  end

  # returns the current thread count that is currently active
  # a status of false or nil means the thread completed
  # so when anything else we count that as a active thread
  def current_thread_count(items)
    active_threads = items.find_all do |_item, opts|
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
      @max_thread_limit = if ENV['MAX_FIXTURE_THREAD_COUNT'].to_i > 0
                            ENV['MAX_FIXTURE_THREAD_COUNT'].to_i
                          else
                            10 # the default
                          end
    end
    @max_thread_limit
  end

  def check_directory_for_symlinks(dir = '.')
    dir = Pathname.new(dir) unless dir.is_a?(Pathname)
    results = []

    dir.each_child(true) do |child|
      if child.symlink?
        results << child
      elsif child.directory? && child.basename.to_s != '.git'
        results.concat(check_directory_for_symlinks(child))
      end
    end

    results
  end
end
include PuppetlabsSpecHelper::Tasks::FixtureHelpers

desc 'Create the fixtures directory'
task :spec_prep do
  # Ruby only sets File::ALT_SEPARATOR on Windows and Rubys standard library
  # uses this to check for Windows
  is_windows = !!File::ALT_SEPARATOR
  if is_windows
    begin
      require 'win32/dir'
    rescue LoadError
      $stderr.puts 'win32-dir gem not installed, falling back to executing mklink directly'
    end
  end

  # git has a race condition creating that directory, that would lead to aborted clone operations
  FileUtils.mkdir_p('spec/fixtures/modules')

  repositories.each do |remote, opts|
    scm = 'git'
    target = opts['target']
    subdir = opts['subdir']
    ref = opts['ref']
    scm = opts['scm'] if opts['scm']
    branch = opts['branch'] if opts['branch']
    flags = opts['flags']
    # get the current active threads that are alive
    count = current_thread_count(repositories)
    if count < max_thread_limit
      logger.debug "New Thread started for #{remote}"
      # start up a new thread and store it in the opts hash
      opts[:thread] = Thread.new do
        if valid_repo?(scm, target, remote)
          update_repo(scm, target)
        else
          clone_repo(scm, remote, target, subdir, ref, branch, flags)
        end
        revision(scm, target, ref) if ref
        remove_subdirectory(target, subdir) if subdir
      end
    else
      # the last thread started should be the longest wait
      item, item_opts = repositories.find_all { |_i, o| o.key?(:thread) }.last
      logger.debug "Waiting on #{item}"
      item_opts[:thread].join # wait for the thread to finish
      # now that we waited lets try again
      redo
    end
  end

  # wait for all the threads to finish
  repositories.each { |_remote, opts| opts[:thread].join }

  fixtures('symlinks').each do |target, link|
    link = link['target']
    next if File.symlink?(link)
    logger.info("Creating symlink from #{link} to #{target}")
    if is_windows
      target = File.join(File.dirname(link), target) unless Pathname.new(target).absolute?
      if Dir.respond_to?(:create_junction)
        Dir.create_junction(link, target)
      else
        system("call mklink /J \"#{link.tr('/', '\\')}\" \"#{target.tr('/', '\\')}\"")
      end
    else
      FileUtils.ln_sf(target, link)
    end
  end

  fixtures('forge_modules').each do |remote, opts|
    ref = ''
    flags = ''
    if opts.instance_of?(String)
      target = opts
    elsif opts.instance_of?(Hash)
      target = opts['target']
      ref = " --version #{opts['ref']}" unless opts['ref'].nil?
      flags = " #{opts['flags']}" if opts['flags']
    end

    next if File.directory?(target)

    working_dir = module_working_directory
    target_dir = File.expand_path('spec/fixtures/modules')

    command = 'puppet module install' + ref + flags + \
              ' --ignore-dependencies' \
              ' --force' \
              " --module_working_dir \"#{working_dir}\"" \
              " --target-dir \"#{target_dir}\" \"#{remote}\""

    unless system(command)
      raise "Failed to install module #{remote} to #{target_dir}"
    end
  end

  FileUtils.mkdir_p('spec/fixtures/manifests')
  FileUtils.touch('spec/fixtures/manifests/site.pp')
end

desc 'Clean up the fixtures directory'
task :spec_clean do
  fixtures('repositories').each do |_remote, opts|
    target = opts['target']
    FileUtils.rm_rf(target)
  end

  fixtures('forge_modules').each do |_remote, opts|
    target = opts['target']
    FileUtils.rm_rf(target)
  end

  FileUtils.rm_rf(module_working_directory)

  Rake::Task[:spec_clean_symlinks].invoke

  if File.zero?('spec/fixtures/manifests/site.pp')
    FileUtils.rm_f('spec/fixtures/manifests/site.pp')
  end
end

desc 'Clean up any fixture symlinks'
task :spec_clean_symlinks do
  fixtures('symlinks').each do |_source, opts|
    target = opts['target']
    FileUtils.rm_f(target)
  end
end
