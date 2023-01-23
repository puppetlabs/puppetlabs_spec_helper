require 'bundler/gem_tasks'
require 'puppetlabs_spec_helper/tasks/fixtures'

task :default => :spec

#### RUBOCOP ####
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

#### RSPEC ####
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  # thanks to the fixtures/modules/ symlinks this needs to exclude fixture modules explicitely
  excludes = ['fixtures/**/*.rb,fixtures/modules/*/**/*.rb']
  if RUBY_PLATFORM == 'java'
    excludes += ['acceptance/**/*.rb', 'integration/**/*.rb', 'puppet/resource_api/*_context_spec.rb', 'puppet/util/network_device/simple/device_spec.rb']
    t.rspec_opts = '--tag ~agent_test'
    t.rspec_opts << ' --tag ~j17_exclude' if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.0.0')
  end
  t.exclude_pattern = "spec/{#{excludes.join ','}}"
end

task :spec => :spec_prep

namespace :spec do
  desc 'Run RSpec code examples with coverage collection'
  task :coverage do
    ENV['SIMPLECOV'] = 'yes'
    Rake::Task['spec'].execute
  end

  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = "spec/puppet/**/*_spec.rb,spec/integration/**/*_spec.rb"
  end

  task :unit => :spec_prep
end

#### LICENSE_FINDER ####
desc 'Check for unapproved licenses in dependencies'
task(:license_finder) do
  system('license_finder --decisions-file=.dependency_decisions.yml') || raise(StandardError, 'Unapproved license(s) found on dependencies')
end

#### CHANGELOG ####
begin
  require 'github_changelog_generator/task'
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    require 'puppet/resource_api/version'
    config.future_release = "v#{Puppet::ResourceApi::VERSION}"
    config.header = "# Changelog\n\n" \
      "All significant changes to this repo will be summarized in this file.\n"
    # config.include_labels = %w[enhancement bug]
    config.user = 'puppetlabs'
    config.project = 'puppet-resource_api'
  end
rescue LoadError
  desc 'Install github_changelog_generator to get access to automatic changelog generation'
  task :changelog do
    raise 'Install github_changelog_generator to get access to automatic changelog generation'
  end
end
