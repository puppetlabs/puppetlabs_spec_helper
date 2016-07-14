require 'rake'
require 'beaker/rake_tasks'
require 'fixtures/rake_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yaml'

# optional gems
begin
  require 'metadata-json-lint/rake_task'
rescue LoadError
  # ignore
end

task :default => [:help]

desc "Run spec tests on an existing fixtures directory"
RSpec::Core::RakeTask.new(:spec_standalone) do |t|
  t.rspec_opts = ['--color']

  pattern = 'spec/{classes,defines,unit,functions,hosts,integration,types}/**/*_spec.rb'
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

desc "Run spec tests and clean the fixtures directory if successful"
task :spec do
  Rake::Task[:spec_prep].invoke
  Rake::Task[:spec_standalone].invoke
  Rake::Task[:spec_clean].invoke
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

RuboCop::RakeTask.new

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
    'class_inherits_from_params_class',
    'class_parameter_defaults',
    'documentation',
    'single_quote_string_with_variables']
  config.ignore_paths = ["tests/**/*.pp", "vendor/**/*.pp","examples/**/*.pp", "spec/**/*.pp", "pkg/**/*.pp"]
end

require 'puppet-syntax/tasks/puppet-syntax'
PuppetSyntax.exclude_paths ||= []
PuppetSyntax.exclude_paths << "spec/fixtures/**/*"
PuppetSyntax.exclude_paths << "pkg/**/*"
PuppetSyntax.exclude_paths << "vendor/**/*"
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

desc "Runs all nessesary checks on a module in preparation for a release"
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
