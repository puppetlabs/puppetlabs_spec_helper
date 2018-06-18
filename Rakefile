# encoding: utf-8

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

def gem_present(name)
  !Bundler.rubygems.find_name(name).empty?
end

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb'].exclude('spec/fixtures/**/*_spec.rb')
end

require 'yard'
YARD::Rake::YardocTask.new

default_tasks = [:spec]

if gem_present 'rubocop'
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
  default_tasks.unshift(:rubocop)
end

task default: default_tasks

#### CHANGELOG ####
begin
  require 'github_changelog_generator/task'
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    require 'puppetlabs_spec_helper/version'
    config.since_tag = 'v2.8.0'
    config.future_release = "v#{PuppetlabsSpecHelper::VERSION}"
    config.header = "# Changelog\n\n" \
      "All significant changes to this repo will be summarized in this file.\n"
    # config.include_labels = %w[enhancement bug]
    config.user = 'puppetlabs'
    config.project = 'puppetlabs_spec_helper'
  end
rescue LoadError
  desc 'Install github_changelog_generator to get access to automatic changelog generation'
  task :changelog do
    raise 'Install github_changelog_generator to get access to automatic changelog generation'
  end
end
