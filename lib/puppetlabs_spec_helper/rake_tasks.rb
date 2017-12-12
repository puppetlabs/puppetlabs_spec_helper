require 'fileutils'
require 'rake'
require 'rspec/core/rake_task'
require 'tmpdir'
require 'yaml'
require 'pathname'
require 'puppetlabs_spec_helper/version'

# optional gems
begin
  require 'metadata-json-lint/rake_task'
rescue LoadError
  # ignore
end

parallel_tests_loaded = false
begin
  require 'parallel_tests'
  parallel_tests_loaded = true
rescue LoadError
  # ignore
end


task :default => [:help]

pattern = 'spec/{aliases,classes,defines,unit,functions,hosts,integration,type_aliases,types}/**/*_spec.rb'

RSpec::Core::RakeTask.new(:spec_standalone) do |t, args|
  t.rspec_opts = ['--color']
  t.rspec_opts << ENV['CI_SPEC_OPTIONS'] unless ENV['CI_SPEC_OPTIONS'].nil?
  if ENV['CI_NODE_TOTAL'] && ENV['CI_NODE_INDEX']
    ci_total = ENV['CI_NODE_TOTAL'].to_i
    ci_index = ENV['CI_NODE_INDEX'].to_i
    raise "CI_NODE_INDEX must be between 1-#{ci_total}" unless ci_index >= 1 && ci_index <= ci_total
    files = Rake::FileList[pattern].to_a
    per_node = (files.size / ci_total.to_f).ceil
    t.pattern = if args.extras.nil? || args.extras.empty?
                  files.each_slice(per_node).to_a[ci_index - 1] || files.first
                else
                  args.extras.join(",")
                end
  else
    if args.extras.nil? || args.extras.empty?
      t.pattern = pattern
    else
      t.pattern = args.extras.join(",")
    end
  end
end

desc "List spec tests in a JSON document"
RSpec::Core::RakeTask.new(:spec_list_json) do |t|
  t.rspec_opts = ['--dry-run', '--format', 'json']
  t.pattern = pattern
end

desc "Run beaker acceptance tests"
RSpec::Core::RakeTask.new(:beaker) do |t|
  t.rspec_opts = ['--color']
  t.pattern = 'spec/acceptance'
  # TEST_TIERS env variable is a comma separated list of tiers to run. e.g. low, medium, high
  if ENV['TEST_TIERS']
    tiers = '--tag '
    test_tiers = ENV['TEST_TIERS'].split(',')
    raise 'TEST_TIERS env variable must have at least 1 tier specified. low, medium or high (comma separated).' if test_tiers.count == 0
    test_tiers.each do |tier|
      tier_to_add = tier.strip
      raise "#{tier_to_add} not a valid test tier." unless %w(low medium high).include?(tier_to_add)
      tiers += "tier_#{tier_to_add},"
    end
    tiers = tiers.chomp(',')
    t.rspec_opts.push(tiers)
  else
    puts 'TEST_TIERS env variable not defined. Defaulting to run all tests.'
  end
end

module PuppetlabsSpecHelper::RakeTasks
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

  # get the array of Beaker set names
  # @return [Array<String>]
  def beaker_node_sets
    return @beaker_nodes if @beaker_nodes
    @beaker_nodes = Dir['spec/acceptance/nodesets/*.yml'].sort.map do |node_set|
      node_set.slice!('.yml')
      File.basename(node_set)
    end
  end

  # Use "vagrant ssh" to login to the given node in the node set
  # @param set [String] The name of the node set (yml file)
  # @param node [String] The name of the node in the set. For multi-node sets.
  def vagrant_ssh(set, node = nil)
    vagrant_yml_dir = File.join '.vagrant', 'beaker_vagrant_files', "#{set}.yml"
    vagrant_file = File.join vagrant_yml_dir, 'Vagrantfile'
    unless File.file? vagrant_file
      puts "There is no Vagrantfile at: '#{vagrant_file}'. Perhaps, the node is not created or is destroyed."
      exit 1
    end
    Dir.chdir(vagrant_yml_dir) do
      command = 'vagrant ssh'
      command += " #{node}" if node
      # Vagrant is not distributed as a normal gem
      # and we should protect it from the current Ruby environment
      env = {
          'RUBYLIB' => nil,
          'GEM_PATH' => nil,
          'BUNDLE_BIN_PATH' => nil,
      }
      system env, command
    end
  end

  def auto_symlink
    { File.basename(Dir.pwd).split('-').last => '#{source_dir}' }
  end

  def fixtures(category)
    if ENV['FIXTURES_YML']
      fixtures_yaml = ENV['FIXTURES_YML']
    elsif File.exists?('.fixtures.yml')
      fixtures_yaml = '.fixtures.yml'
    elsif File.exists?('.fixtures.yaml')
      fixtures_yaml = '.fixtures.yaml'
    else
      fixtures_yaml = false
    end

    begin
      if fixtures_yaml
        fixtures = YAML.load_file(fixtures_yaml) || { 'fixtures' => {} }
      else
        fixtures = { 'fixtures' => {} }
      end
    rescue Errno::ENOENT
      fail("Fixtures file not found: '#{fixtures_yaml}'")
    rescue Psych::SyntaxError => e
      fail("Found malformed YAML in '#{fixtures_yaml}' on line #{e.line} column #{e.column}: #{e.problem}")
    end

    unless fixtures.include?('fixtures')
      # File is non-empty, but does not specify fixtures
      fail("No 'fixtures' entries found in '#{fixtures_yaml}'; required")
    end

    if fixtures.include? 'defaults'
      fixture_defaults = fixtures['defaults']
    else
      fixture_defaults = {}
    end

    fixtures = fixtures['fixtures']

    if fixtures['symlinks'].nil?
      fixtures['symlinks'] = auto_symlink
    end

    result = {}
    if fixtures.include? category and fixtures[category] != nil

      defaults = { "target" => "spec/fixtures/modules" }

      # load defaults from the `.fixtures.yml` `defaults` section
      # for the requested category and merge them into my defaults
      if fixture_defaults.include? category
        defaults = defaults.merge(fixture_defaults[category])
      end

      fixtures[category].each do |fixture, opts|
        # convert a simple string fixture to a hash, by
        # using the string fixture as the `repo` option of the hash.
        if opts.instance_of?(String)
          opts = { "repo" => opts }
        end
        # there should be a warning or something if it's not a hash...
        if opts.instance_of?(Hash)
          # merge our options into the defaults to get the
          # final option list
          opts = defaults.merge(opts)

          real_target = eval('"'+opts["target"]+'"')
          real_source = eval('"'+opts["repo"]+'"')

          result[real_source] = { "target" => File.join(real_target,fixture), "ref" => opts["ref"], "branch" => opts["branch"], "scm" => opts["scm"], "flags" => opts["flags"], "subdir" => opts["subdir"]}
        end
      end
    end
    return result
  end

  def clone_repo(scm, remote, target, subdir=nil, ref=nil, branch=nil, flags = nil)
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
      args.push('update', '--clean', '-r', ref)
    when 'git'
      args.push('reset', '--hard', ref)
    else
      fail "Unfortunately #{scm} is not supported yet"
    end
    system("cd #{target} && #{scm} #{args.flatten.join ' '}")
  end

  def remove_subdirectory(target, subdir)
    unless subdir.nil?
      Dir.mktmpdir {|tmpdir|
         FileUtils.mv(Dir.glob("#{target}/#{subdir}/{.[^\.]*,*}"), tmpdir)
         FileUtils.rm_rf("#{target}/#{subdir}")
         FileUtils.mv(Dir.glob("#{tmpdir}/{.[^\.]*,*}"), "#{target}")
      }
    end
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
      @logger = Logger.new(STDERR)
      @logger.level = level
    end
    @logger
  end

  def module_working_directory
    # The problem with the relative path is that PMT doesn't expand the path properly and so passing in a relative path here
    # becomes something like C:\somewhere\backslashes/spec/fixtures/work-dir on Windows, and then PMT barfs itself.
    # This has been reported as https://tickets.puppetlabs.com/browse/PUP-4884
    File.expand_path(ENV['MODULE_WORKING_DIR'] ? ENV['MODULE_WORKING_DIR'] : 'spec/fixtures/work-dir')
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

  def check_directory_for_symlinks(dir='.')
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
include PuppetlabsSpecHelper::RakeTasks

desc "Create the fixtures directory"
task :spec_prep do
  # Ruby only sets File::ALT_SEPARATOR on Windows and Rubys standard library
  # uses this to check for Windows
  is_windows = !!File::ALT_SEPARATOR
  if is_windows
    begin
      require 'win32/dir'
    rescue LoadError
      $stderr.puts "win32-dir gem not installed, falling back to executing mklink directly"
    end
  end

  # git has a race condition creating that directory, that would lead to aborted clone operations
  FileUtils::mkdir_p("spec/fixtures/modules")

  repositories.each do |remote, opts|
    scm = 'git'
    target = opts["target"]
    subdir = opts["subdir"]
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
        clone_repo(scm, remote, target, subdir, ref, branch, flags)
        revision(scm, target, ref) if ref
        remove_subdirectory(target, subdir) if subdir
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

  fixtures("symlinks").each do |target, link|
    link = link['target']
    unless File.symlink?(link)
      logger.info("Creating symlink from #{link} to #{target}")
      if is_windows
        target = File.join(File.dirname(link), target) unless Pathname.new(target).absolute?
        if Dir.respond_to?(:create_junction)
          Dir.create_junction(link, target)
        else
          system("call mklink /J \"#{link.gsub('/', '\\')}\" \"#{target.gsub('/', '\\')}\"")
        end
      else
        FileUtils::ln_sf(target, link)
      end
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

    working_dir = module_working_directory
    target_dir = File.expand_path('spec/fixtures/modules')

    command = "puppet module install" + ref + flags + \
      " --ignore-dependencies" \
      " --force" \
      " --module_working_dir \"#{working_dir}\"" \
      " --target-dir \"#{target_dir}\" \"#{remote}\""

    unless system(command)
      fail "Failed to install module #{remote} to #{target_dir}"
    end
  end

  FileUtils::mkdir_p("spec/fixtures/manifests")
  FileUtils::touch("spec/fixtures/manifests/site.pp")
end

desc "Clean up the fixtures directory"
task :spec_clean do
  fixtures("repositories").each do |remote, opts|
    target = opts["target"]
    FileUtils::rm_rf(target)
  end

  fixtures("forge_modules").each do |remote, opts|
    target = opts["target"]
    FileUtils::rm_rf(target)
  end

  FileUtils::rm_rf(module_working_directory)

  fixtures("symlinks").each do |source, opts|
    target = opts["target"]
    FileUtils::rm_f(target)
  end

  if File.zero?("spec/fixtures/manifests/site.pp")
    FileUtils::rm_f("spec/fixtures/manifests/site.pp")
  end

end

desc "Run spec tests and clean the fixtures directory if successful"
task :spec do |t, args|
  begin
    Rake::Task[:spec_prep].invoke
    Rake::Task[:spec_standalone].invoke(*args.extras)
  ensure
    Rake::Task[:spec_clean].invoke
  end
end

desc "Parallel spec tests"
task :parallel_spec do
  raise 'Add the parallel_tests gem to Gemfile to enable this task' unless parallel_tests_loaded
  if Rake::FileList[pattern].to_a.empty?
    warn "No files for parallel_spec to run against"
  else
    begin
      args = ['-t', 'rspec']
      args.push('--').concat(ENV['CI_SPEC_OPTIONS'].strip.split(' ')).push('--') unless ENV['CI_SPEC_OPTIONS'].nil? || ENV['CI_SPEC_OPTIONS'].strip.empty?
      args.concat(Rake::FileList[pattern].to_a)

      Rake::Task[:spec_prep].invoke
      ParallelTests::CLI.new.run(args)
    ensure
      Rake::Task[:spec_clean].invoke
    end
  end
end

desc "List available beaker nodesets"
task 'beaker:sets' do
  beaker_node_sets.each do |set|
    puts set
  end
end

# alias for compatibility
task 'beaker_nodes' => 'beaker:sets'

desc 'Try to use vagrant to login to the Beaker node'
task 'beaker:ssh', [:set, :node] do |_task, args|
  set = args[:set] || ENV['BEAKER_set'] || ENV['RS_SET'] || 'default'
  node = args[:node]
  vagrant_ssh set, node
end

beaker_node_sets.each do |set|
  desc "Run the Beaker acceptance tests for the node set '#{set}'"
  task "beaker:#{set}" do
    ENV['BEAKER_set'] = set
    Rake::Task['beaker'].reenable
    Rake::Task['beaker'].invoke
  end

  desc "Use vagrant to login to a node from the set '#{set}'"
  task "beaker:ssh:#{set}", [:node] do |_task, args|
    node = args[:node]
    vagrant_ssh set, node
  end
end

desc "Build puppet module package"
task :build do
  # This will be deprecated once puppet-module is a face.
  begin
    Gem::Specification.find_by_name('puppet-module')
  rescue Gem::LoadError, NoMethodError
    require 'puppet/face'
    pmod = Puppet::Face['module', :current]
    pmod.build('./')
  end
end

desc "Clean a built module package"
task :clean do
  FileUtils.rm_rf("pkg/")
end

require 'puppet-lint/tasks/puppet-lint'
# Must clear as it will not override the existing puppet-lint rake task since we require to import for
# the PuppetLint::RakeTask
Rake::Task[:lint].clear
# Relative is not able to be set within the context of PuppetLint::RakeTask
PuppetLint.configuration.relative = true
PuppetLint::RakeTask.new(:lint) do |config|
  config.fail_on_warnings = true
  config.disable_checks = [
    '80chars',
    '140chars',
    'class_inherits_from_params_class',
    'class_parameter_defaults',
    'documentation',
    'single_quote_string_with_variables']
  config.ignore_paths = [
    "bundle/**/*.pp",
    "pkg/**/*.pp",
    "spec/**/*.pp",
    "tests/**/*.pp",
    "types/**/*.pp",
    "vendor/**/*.pp",
  ]
end

require 'puppet-syntax/tasks/puppet-syntax'
PuppetSyntax.exclude_paths ||= []
PuppetSyntax.exclude_paths << "spec/fixtures/**/*"
PuppetSyntax.exclude_paths << "pkg/**/*"
PuppetSyntax.exclude_paths << "vendor/**/*"
if Puppet.version.to_f < 4.0
  PuppetSyntax.exclude_paths << "types/**/*"
end
PuppetSyntax.future_parser = true if ENV['FUTURE_PARSER'] == 'yes'

desc "Check syntax of Ruby files and call :syntax and :metadata_lint"
task :validate do
  Dir['lib/**/*.rb'].each do |lib_file|
    sh "ruby -c #{lib_file}"
  end

  Rake::Task[:syntax].invoke
  if File.exist?('metadata.json')
    if Rake::Task.task_defined?(:metadata_lint)
      Rake::Task[:metadata_lint].invoke
    else
      warn "Skipping metadata validation; the metadata-json-lint gem was not found"
    end
  end
end

task :metadata do
  warn "The 'metadata' task is deprecated. Please use 'metadata_lint' instead."
  if Rake::Task.task_defined?(:metadata_lint)
    Rake::Task[:metadata_lint].invoke
  else
    warn "Skipping metadata validation; the metadata-json-lint gem was not found"
  end
end

desc "Print development version of module"
task :compute_dev_version do
  version = ''
  if File.exists?( 'metadata.json' )
    require 'json'

    modinfo = JSON.parse(File.read( 'metadata.json' ))
    version = modinfo['version']
  elsif File.exists?( 'Modulefile' )
    modfile = File.read('Modulefile')
    version = modfile.match(/\nversion[ ]+['"](.*)['"]/)[1]
  else
    fail "Could not find a metadata.json or Modulefile! Cannot compute dev version without one or the other!"
  end

  sha = `git rev-parse HEAD`[0..7]
  branch = `git rev-parse --abbrev-ref HEAD`

  # If we're in a CI environment include our build number
  # If the branch is a release branch we append an 'r' into the new_version,
  # this is due to the release branch buildID conflicting with master branch when trying to push to the staging forge.
  # More info can be found at https://tickets.puppetlabs.com/browse/FM-6170
  if build = ENV['BUILD_NUMBER'] || ENV['TRAVIS_BUILD_NUMBER']
    if branch.eql? "release"
      new_version = sprintf('%s-%s%04d-%s', version, "r", build, sha)
    else
      new_version = sprintf('%s-%04d-%s', version, build, sha)
    end
  else
    new_version = "#{version}-#{sha}"
  end

  print new_version
end

desc "Runs all necessary checks on a module in preparation for a release"
task :release_checks do
  Rake::Task[:lint].invoke
  Rake::Task[:validate].invoke
  if parallel_tests_loaded
    Rake::Task[:parallel_spec].invoke
  else
    Rake::Task[:spec].invoke
  end
  Rake::Task["check:symlinks"].invoke
  Rake::Task["check:test_file"].invoke
  Rake::Task["check:dot_underscore"].invoke
  Rake::Task["check:git_ignore"].invoke
end

namespace :check do
  desc "Fails if symlinks are present in directory"
  task :symlinks do
    symlinks = check_directory_for_symlinks
    unless symlinks.empty?
      symlinks.each { |r| puts "Symlink found: #{r.to_s} => #{r.readlink}" }
      fail "Symlink(s) exist within this directory"
    end
  end

  desc "Fails if .pp files present in tests folder"
  task :test_file do
    if Dir.exist?("tests")
      Dir.chdir("tests")
      ppfiles = Dir["*.pp"]
      unless ppfiles.empty?
        puts ppfiles
        fail ".pp files present in tests folder; Move them to an examples folder following the new convention"
      end
    end
  end

  desc "Fails if any ._ files are present in directory"
  task :dot_underscore do
    dirs = Dir["._*"]
    unless dirs.empty?
      puts dirs
      fail "._ files are present in the directory"
    end
  end

  desc "Fails if directories contain the files specified in .gitignore"
  task :git_ignore do
    matched = `git ls-files --ignored --exclude-standard`
    unless matched == ""
      puts matched
      fail "File specified in .gitignore has been committed"
    end
  end
end

desc "Display the list of available rake tasks"
task :help do
  system("rake -T")
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop) do |task|
    # These make the rubocop experience maybe slightly less terrible
    task.options = ['-D', '-S', '-E']
  end
rescue LoadError
  desc "rubocop is not available in this installation"
  task :rubocop do
    fail "rubocop is not available in this installation"
  end
end

module_dir = Dir.pwd
locales_dir = File.absolute_path('locales',  module_dir )
# if the task is allowed to run when the module does not have a locales directory,
# the task is run in the puppet gem instead and creates a POT there.
puts "gettext-setup tasks will only be loaded if the locales/ directory is present" if Rake.verbose == true
if File.exist? locales_dir
  begin
    spec = Gem::Specification.find_by_name 'gettext-setup'
    load "#{spec.gem_dir}/lib/tasks/gettext.rake"
    # Initialization requires a valid locales directory
    GettextSetup.initialize(locales_dir)
  rescue Gem::LoadError
    puts "No gettext-setup gem found, skipping gettext initialization" if Rake.verbose == true
  end
  namespace :module do
  desc "Runs all tasks to build a modules POT file for internationalization"
    task :pot_gen do
      Rake::Task["gettext:pot"].invoke()
      Rake::Task["gettext:metadata_pot"].invoke("#{module_dir}/metadata.json")
    end
  end
end
