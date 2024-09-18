# frozen_string_literal: true

require 'fileutils'
require 'rake'
require 'rspec/core/rake_task'
require 'tmpdir'
require 'pathname'
require 'puppetlabs_spec_helper/version'
require 'puppetlabs_spec_helper/tasks/fixtures'
require 'puppetlabs_spec_helper/tasks/check_symlinks'
require 'English'

# optional gems
begin
  require 'metadata-json-lint/rake_task'
rescue LoadError
  # ignore
end

begin
  require 'puppet_blacksmith/rake_tasks'
rescue LoadError
  # ignore
end

begin
  require 'github_changelog_generator/task'
rescue LoadError
  # ignore
end

begin
  require 'puppet-strings/tasks'
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

pattern = 'spec/{aliases,classes,defines,functions,hosts,integration,plans,tasks,type_aliases,types,unit}/**/*_spec.rb'

RSpec::Core::RakeTask.new(:spec_standalone) do |t, args|
  t.rspec_opts = []
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
  Rake::Task[:spec_prep].invoke
  Rake::Task[:spec_standalone].invoke(*args.extras)
  Rake::Task[:spec_clean].invoke
ensure
  Rake::Task[:spec_clean_symlinks].invoke
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
  Rake::Task[:spec_prep].invoke
  Rake::Task[:parallel_spec_standalone].invoke(*args.extras)
  Rake::Task[:spec_clean].invoke
ensure
  Rake::Task[:spec_clean_symlinks].invoke
end

desc 'Parallel spec tests'
task :parallel_spec_standalone do |_t, args|
  raise 'Add the parallel_tests gem to Gemfile to enable this task' unless parallel_tests_loaded

  if Rake::FileList[pattern].to_a.empty?
    warn 'No files for parallel_spec to run against'
  else

    args = ['--type', 'rspec']
    additional_options = ['--format', 'progress'] + ENV['CI_SPEC_OPTIONS'].to_s.strip.split
    args.push('--').concat(additional_options).push('--')
    args.concat(Rake::FileList[pattern].to_a)

    ParallelTests::CLI.new.run(args)

  end
end

require 'puppet-lint/tasks/puppet-lint'
# Must clear as it will not override the existing puppet-lint rake task since we require to import for
# the PuppetLint::RakeTask
Rake::Task[:lint].clear
PuppetLint.configuration.fail_on_warnings = true
# Utilize PuppetLint global configuration so that these settings can be tweaked by
# spec_helper.rb in an individual module
PuppetLint.configuration.relative = true
PuppetLint.configuration.ignore_paths ||= []
PuppetLint.configuration.ignore_paths << '.vendor/**/*.pp'
PuppetLint.configuration.ignore_paths << 'bundle/**/*.pp'
PuppetLint.configuration.ignore_paths << 'pkg/**/*.pp'
PuppetLint.configuration.ignore_paths << 'spec/**/*.pp'
PuppetLint.configuration.ignore_paths << 'tests/**/*.pp'
PuppetLint.configuration.ignore_paths << 'types/**/*.pp'
PuppetLint.configuration.ignore_paths << 'vendor/**/*.pp'
puppet_lint_disable_checks = %w[
  80chars
  140chars
  class_inherits_from_params_class
  disable_autoloader_layout
  documentation
  single_quote_string_with_variables
]

puppet_lint_disable_checks.each do |check|
  PuppetLint.configuration.send(:"disable_#{check}")
end
PuppetLint::RakeTask.new(:lint)

desc 'Run puppet-lint and fix issues automatically'
PuppetLint::RakeTask.new(:lint_fix) do |config|
  config.fix = true
end

require 'puppet-syntax/tasks/puppet-syntax'
PuppetSyntax.exclude_paths ||= []
PuppetSyntax.exclude_paths << 'spec/fixtures/**/*'
PuppetSyntax.exclude_paths << 'pkg/**/*'
PuppetSyntax.exclude_paths << 'vendor/**/*'
PuppetSyntax.exclude_paths << '.vendor/**/*'
PuppetSyntax.check_hiera_keys = true
PuppetSyntax.check_hiera_data = true

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

  if File.exist?('REFERENCE.md')
    if Rake::Task.task_defined?('strings:validate:reference')
      Rake::Task['strings:validate:reference'].invoke
    else
      warn 'Skipping reference documentation validation; the puppet-strings gem was not found'
    end
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
    version = modfile.match(/\nversion +['"](.*)['"]/)[1]
  else
    raise 'Could not find a metadata.json or Modulefile! Cannot compute dev version without one or the other!'
  end

  sha = `git rev-parse HEAD`[0..7]
  branch = `git rev-parse --abbrev-ref HEAD`

  # If we're in a CI environment include our build number
  # If the branch is a release branch we append an 'r' into the new_version,
  # this is due to the release branch buildID conflicting with main branch when trying to push to the staging forge.
  # More info can be found at https://tickets.puppetlabs.com/browse/FM-6170
  new_version = if (build = ENV.fetch('BUILD_NUMBER', nil))
                  if branch.eql? 'release'
                    format('%s-%s%04d-%s', version, 'r', build, sha) # legacy support code
                  else
                    format('%s-%04d-%s', version, build, sha) # legacy support code
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
  Rake::Task[:check].invoke
end

namespace :check do
  desc 'Fails if symlinks are present in directory'
  task :symlinks do
    symlinks = PuppetlabsSpecHelper::Tasks::CheckSymlinks.new.check
    unless symlinks.empty?
      symlinks.each { |r| puts "Symlink found: #{r} => #{r.readlink}" }
      raise 'Symlink(s) exist within this directory'
    end
  end

  desc 'Fails if .pp files present in tests folder'
  task :test_file do
    ppfiles = Dir[File.join('tests', '**', '*.pp')]
    unless ppfiles.empty?
      puts ppfiles
      raise '.pp files present in tests folder; Move them to an examples folder following the new convention'
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
    matched = `git ls-files --ignored --exclude-standard --cached`
    raise 'git ls-files failed' unless $CHILD_STATUS.success?

    unless matched == ''
      puts matched
      raise 'File specified in .gitignore has been committed'
    end
  end
end

desc 'Run static pre release checks'
task check: ['check:symlinks', 'check:test_file', 'check:dot_underscore', 'check:git_ignore']

desc 'Display the list of available rake tasks'
task :help do
  system('rake -T')
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop) do |task|
    # These make the rubocop experience maybe slightly less terrible
    task.options = ['-D', '-S', '-E']

    # Use Rubocop's Github Actions formatter if possible
    if ENV['GITHUB_ACTIONS'] == 'true'
      rubocop_spec = Gem::Specification.find_by_name('rubocop')
      task.formatters << 'github' if Gem::Version.new(rubocop_spec.version) >= Gem::Version.new('1.2')
    end
  end
rescue LoadError
  desc 'rubocop is not available in this installation'
  task :rubocop do
    raise 'rubocop is not available in this installation'
  end
end

def create_gch_task(changelog_user = nil, changelog_project = nil, changelog_since_tag = nil, changelog_tag_pattern = 'v%s')
  if Bundler.rubygems.find_name('github_changelog_generator').any?
    # needed a place to hide these methods
    # rubocop:disable Lint/NestedMethodDefinition
    def changelog_user_from_metadata
      result = JSON.parse(File.read('metadata.json'))['author']
      raise 'unable to find the changelog_user in .sync.yml, or the author in metadata.json' if result.nil?

      puts "GitHubChangelogGenerator user:#{result}"
      result
    end

    def changelog_project_from_metadata
      result = JSON.parse(File.read('metadata.json'))['name']
      raise 'unable to find the changelog_project in .sync.yml or the name in metadata.json' if result.nil?

      puts "GitHubChangelogGenerator project:#{result}"
      result
    end

    def changelog_future_release
      return unless Rake.application.top_level_tasks.include? 'changelog'

      result = JSON.parse(File.read('metadata.json'))['version']
      raise 'unable to find the future_release (version) in metadata.json' if result.nil?

      puts "GitHubChangelogGenerator future_release:#{result}"
      result
    end
    # rubocop:enable Lint/NestedMethodDefinition

    GitHubChangelogGenerator::RakeTask.new :changelog do |config|
      raise "Set CHANGELOG_GITHUB_TOKEN environment variable eg 'export CHANGELOG_GITHUB_TOKEN=valid_token_here'" if ENV['CHANGELOG_GITHUB_TOKEN'].nil?

      config.user = changelog_user || changelog_user_from_metadata
      config.project = changelog_project || changelog_project_from_metadata
      config.since_tag = changelog_since_tag if changelog_since_tag
      config.future_release = changelog_tag_pattern % changelog_future_release.to_s
      config.exclude_labels = ['maintenance']
      config.header = "# Change log\n\nAll notable changes to this project will be documented in this file. " \
                      'The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project adheres ' \
                      'to [Semantic Versioning](https://semver.org).'
      config.add_pr_wo_labels = true
      config.issues = false
      config.merge_prefix = '### UNCATEGORIZED PRS; GO LABEL THEM'
      config.configure_sections = {
        'Changed' => {
          'prefix' => '### Changed',
          'labels' => ['backwards-incompatible'],
        },
        'Added' => {
          'prefix' => '### Added',
          'labels' => %w[feature enhancement],
        },
        'Fixed' => {
          'prefix' => '### Fixed',
          'labels' => ['bugfix'],
        },
      }
    end
  else
    desc 'Generate a Changelog from GitHub'
    task :changelog do
      raise <<~MESSAGE
        The changelog tasks depends on unreleased features of the github_changelog_generator gem.
        Please manually add it to your .sync.yml for now, and run `pdk update`:
        ---
        Gemfile:
          optional:
            ':development':
              - gem: 'github_changelog_generator'
                git: 'https://github.com/skywinder/github-changelog-generator'
                ref: '20ee04ba1234e9e83eb2ffb5056e23d641c7a018'
                condition: "Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.2.2')"
      MESSAGE
    end
  end
end
