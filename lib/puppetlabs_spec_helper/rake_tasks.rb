require 'fileutils'
require 'rake'
require 'rspec/core/rake_task'
require 'tmpdir'
require 'yaml'

# optional gems
begin
  require 'metadata-json-lint/rake_task'
rescue LoadError
  # ignore
end

task :default => [:help]

pattern = 'spec/{aliases,classes,defines,unit,functions,hosts,integration,types}/**/*_spec.rb'

desc "Run spec tests on an existing fixtures directory"
RSpec::Core::RakeTask.new(:spec_standalone) do |t|

  if ENV['CI_NODE_TOTAL'] && ENV['CI_NODE_INDEX']
    ci_total = ENV['CI_NODE_TOTAL'].to_i
    ci_index = ENV['CI_NODE_INDEX'].to_i
    raise "CI_NODE_INDEX must be between 1-#{ci_total}" unless ci_index >= 1 && ci_index <= ci_total

    files = Rake::FileList[pattern].to_a
    per_node = (files.size / ci_total.to_f).ceil
    t.pattern = files.each_slice(per_node).to_a[ci_index - 1] || files.first
  else
    t.pattern = pattern
  end
end

desc "Run beaker acceptance tests"
RSpec::Core::RakeTask.new(:beaker) do |t|
  t.pattern = 'spec/acceptance'
end

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
  { Dir.pwd.split('/').last.split('-').last => '#{source_dir}' }
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
    fixtures = YAML.load_file(ENV['FIXTURES_YML'] || fixtures_yaml)["fixtures"]
  rescue Errno::ENOENT
    fixtures = {}
  rescue Psych::SyntaxError => e
    abort("Found malformed YAML in #{fixtures_yaml} on line #{e.line} column #{e.column}: #{e.problem}")
  end

  if fixtures['symlinks'].nil?
    fixtures['symlinks'] = auto_symlink
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
        result[real_source] = { "target" => target, "ref" => opts["ref"], "branch" => opts["branch"], "scm" => opts["scm"], "flags" => opts["flags"], "subdir" => opts["subdir"]}
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
    @logger = Logger.new(STDOUT)
    @logger.level = level
  end
  @logger
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

desc "Run spec tests and clean the fixtures directory if successful"
task :spec do
  Rake::Task[:spec_prep].invoke
  Rake::Task[:spec_standalone].invoke
  Rake::Task[:spec_clean].invoke
end

desc "Parallel spec tests"
task :parallel_spec do
  begin
    require 'parallel_tests'

    args = ['-t', 'rspec'].
      concat(Rake::FileList[pattern].to_a)

    Rake::Task[:spec_prep].invoke
    ParallelTests::CLI.new.run(args)
    Rake::Task[:spec_clean].invoke
  rescue LoadError
    fail 'Add the parallel_tests gem to Gemfile to enable this task'
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

  # If we're in a CI environment include our build number
  if build = ENV['BUILD_NUMBER'] || ENV['TRAVIS_BUILD_NUMBER']
    new_version = sprintf('%s-%04d-%s', version, build, sha)
  else
    new_version = "#{version}-#{sha}"
  end

  print new_version
end

desc "Runs all necessary checks on a module in preparation for a release"
task :release_checks do
  Rake::Task[:lint].invoke
  Rake::Task[:validate].invoke
  Rake::Task[:spec].invoke
  Rake::Task["check:symlinks"].invoke
  Rake::Task["check:test_file"].invoke
  Rake::Task["check:dot_underscore"].invoke
  Rake::Task["check:git_ignore"].invoke
end

namespace :check do
  desc "Fails if symlinks are present in directory"
  task :symlinks do
    symlink = `find . -path ./.git -prune -o -type l -ls`
    unless symlink == ""
      puts symlink
      fail "A symlink exists within this directory"
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
