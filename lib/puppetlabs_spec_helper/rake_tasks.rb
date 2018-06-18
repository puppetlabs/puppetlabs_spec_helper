require 'fileutils'
require 'rake'
require 'rspec/core/rake_task'
require 'tmpdir'
require 'pathname'
require 'puppetlabs_spec_helper/version'
require 'puppetlabs_spec_helper/tasks/beaker'
require 'puppetlabs_spec_helper/tasks/fixtures'

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

task default: [:help]

pattern = 'spec/{aliases,classes,defines,unit,functions,hosts,integration,plans,type_aliases,types}/**/*_spec.rb'

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
                  args.extras.join(',')
                end
  else
    t.pattern = if args.extras.nil? || args.extras.empty?
                  pattern
                else
                  args.extras.join(',')
                end
  end
end

desc 'List spec tests in a JSON document'
RSpec::Core::RakeTask.new(:spec_list_json) do |t|
  t.rspec_opts = ['--dry-run', '--format', 'json']
  t.pattern = pattern
end

desc 'Run spec tests and clean the fixtures directory if successful'
task :spec do |_t, args|
  begin
    Rake::Task[:spec_prep].invoke
    Rake::Task[:spec_standalone].invoke(*args.extras)
    Rake::Task[:spec_clean].invoke
  ensure
    Rake::Task[:spec_clean_symlinks].invoke
  end
end

desc 'Run spec tests with ruby simplecov code coverage'
namespace :spec do
  task :simplecov do
    ENV['SIMPLECOV'] = 'yes'
    Rake::Task['spec'].execute
  end
end

desc 'Run spec tests in parallel and clean the fixtures directory if successful'
task :parallel_spec do |_t, args|
  begin
    Rake::Task[:spec_prep].invoke
    Rake::Task[:parallel_spec_standalone].invoke(*args.extras)
    Rake::Task[:spec_clean].invoke
  ensure
    Rake::Task[:spec_clean_symlinks].invoke
  end
end

desc 'Parallel spec tests'
task :parallel_spec_standalone do |_t, args|
  raise 'Add the parallel_tests gem to Gemfile to enable this task' unless parallel_tests_loaded
  if Rake::FileList[pattern].to_a.empty?
    warn 'No files for parallel_spec to run against'
  else
    begin
      args = ['-t', 'rspec']
      args.push('--').concat(ENV['CI_SPEC_OPTIONS'].strip.split(' ')).push('--') unless ENV['CI_SPEC_OPTIONS'].nil? || ENV['CI_SPEC_OPTIONS'].strip.empty?
      args.concat(Rake::FileList[pattern].to_a)

      ParallelTests::CLI.new.run(args)
    end
  end
end

desc 'Build puppet module package'
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

desc 'Clean a built module package'
task :clean do
  FileUtils.rm_rf('pkg/')
end

require 'puppet-lint/tasks/puppet-lint'
# Must clear as it will not override the existing puppet-lint rake task since we require to import for
# the PuppetLint::RakeTask
Rake::Task[:lint].clear
# Relative is not able to be set within the context of PuppetLint::RakeTask
PuppetLint.configuration.relative = true
PuppetLint::RakeTask.new(:lint) do |config|
  config.fail_on_warnings = true
  config.disable_checks = %w[
    80chars
    140chars
    class_inherits_from_params_class
    class_parameter_defaults
    documentation
    single_quote_string_with_variables
  ]
  config.ignore_paths = [
    'bundle/**/*.pp',
    'pkg/**/*.pp',
    'spec/**/*.pp',
    'tests/**/*.pp',
    'types/**/*.pp',
    'vendor/**/*.pp',
  ]
end

require 'puppet-syntax/tasks/puppet-syntax'
PuppetSyntax.exclude_paths ||= []
PuppetSyntax.exclude_paths << 'spec/fixtures/**/*'
PuppetSyntax.exclude_paths << 'pkg/**/*'
PuppetSyntax.exclude_paths << 'vendor/**/*'
if Puppet.version.to_f < 4.0
  PuppetSyntax.exclude_paths << 'types/**/*'
end
PuppetSyntax.future_parser = true if ENV['FUTURE_PARSER'] == 'yes'

desc 'Check syntax of Ruby files and call :syntax and :metadata_lint'
task :validate do
  Dir['lib/**/*.rb'].each do |lib_file|
    sh "ruby -c #{lib_file}"
  end

  Rake::Task[:syntax].invoke
  if File.exist?('metadata.json')
    if Rake::Task.task_defined?(:metadata_lint)
      Rake::Task[:metadata_lint].invoke
    else
      warn 'Skipping metadata validation; the metadata-json-lint gem was not found'
    end
  end
end

task :metadata do
  warn "The 'metadata' task is deprecated. Please use 'metadata_lint' instead."
  if Rake::Task.task_defined?(:metadata_lint)
    Rake::Task[:metadata_lint].invoke
  else
    warn 'Skipping metadata validation; the metadata-json-lint gem was not found'
  end
end

desc 'Print development version of module'
task :compute_dev_version do
  version = ''
  if File.exist?('metadata.json')
    require 'json'

    modinfo = JSON.parse(File.read('metadata.json'))
    version = modinfo['version']
  elsif File.exist?('Modulefile')
    modfile = File.read('Modulefile')
    version = modfile.match(%r{\nversion[ ]+['"](.*)['"]})[1]
  else
    raise 'Could not find a metadata.json or Modulefile! Cannot compute dev version without one or the other!'
  end

  sha = `git rev-parse HEAD`[0..7]
  branch = `git rev-parse --abbrev-ref HEAD`

  # If we're in a CI environment include our build number
  # If the branch is a release branch we append an 'r' into the new_version,
  # this is due to the release branch buildID conflicting with master branch when trying to push to the staging forge.
  # More info can be found at https://tickets.puppetlabs.com/browse/FM-6170
  new_version = if build = ENV['BUILD_NUMBER'] || ENV['TRAVIS_BUILD_NUMBER']
                  if branch.eql? 'release'
                    '%s-%s%04d-%s' % [version, 'r', build, sha]
                  else
                    '%s-%04d-%s' % [version, build, sha]
                                end
                else
                  "#{version}-#{sha}"
                end

  print new_version
end

desc 'Runs all necessary checks on a module in preparation for a release'
task :release_checks do
  Rake::Task[:lint].invoke
  Rake::Task[:validate].invoke
  if parallel_tests_loaded
    Rake::Task[:parallel_spec].invoke
  else
    Rake::Task[:spec].invoke
  end
  Rake::Task['check:symlinks'].invoke
  Rake::Task['check:test_file'].invoke
  Rake::Task['check:dot_underscore'].invoke
  Rake::Task['check:git_ignore'].invoke
end

namespace :check do
  desc 'Fails if symlinks are present in directory'
  task :symlinks do
    symlinks = check_directory_for_symlinks
    unless symlinks.empty?
      symlinks.each { |r| puts "Symlink found: #{r} => #{r.readlink}" }
      raise 'Symlink(s) exist within this directory'
    end
  end

  desc 'Fails if .pp files present in tests folder'
  task :test_file do
    if Dir.exist?('tests')
      Dir.chdir('tests')
      ppfiles = Dir['*.pp']
      unless ppfiles.empty?
        puts ppfiles
        raise '.pp files present in tests folder; Move them to an examples folder following the new convention'
      end
    end
  end

  desc 'Fails if any ._ files are present in directory'
  task :dot_underscore do
    dirs = Dir['._*']
    unless dirs.empty?
      puts dirs
      raise '._ files are present in the directory'
    end
  end

  desc 'Fails if directories contain the files specified in .gitignore'
  task :git_ignore do
    matched = `git ls-files --ignored --exclude-standard`
    unless matched == ''
      puts matched
      raise 'File specified in .gitignore has been committed'
    end
  end
end

desc 'Display the list of available rake tasks'
task :help do
  system('rake -T')
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop) do |task|
    # These make the rubocop experience maybe slightly less terrible
    task.options = ['-D', '-S', '-E']
  end
rescue LoadError
  desc 'rubocop is not available in this installation'
  task :rubocop do
    raise 'rubocop is not available in this installation'
  end
end

module_dir = Dir.pwd
locales_dir = File.absolute_path('locales', module_dir)
# if the task is allowed to run when the module does not have a locales directory,
# the task is run in the puppet gem instead and creates a POT there.
puts 'gettext-setup tasks will only be loaded if the locales/ directory is present' if Rake.verbose == true
if File.exist? locales_dir
  begin
    spec = Gem::Specification.find_by_name 'gettext-setup'
    load "#{spec.gem_dir}/lib/tasks/gettext.rake"
    # Initialization requires a valid locales directory
    GettextSetup.initialize_config(locales_dir)
    namespace :module do
      desc 'Runs all tasks to build a modules POT file for internationalization'
      task :pot_gen do
        Rake::Task['gettext:pot'].invoke
        Rake::Task['gettext:metadata_pot'].invoke("#{module_dir}/metadata.json")
      end
    end
  rescue Gem::LoadError
    puts 'No gettext-setup gem found, skipping GettextSetup config initialization' if Rake.verbose == true
  end
end
