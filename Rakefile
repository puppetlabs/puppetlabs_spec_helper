# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require_relative 'lib/puppetlabs_spec_helper/version'
require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "puppetlabs_spec_helper"
  gem.version = "#{PuppetlabsSpecHelper::Version::STRING}"
  gem.homepage = "http://github.com/puppetlabs/puppetlabs_spec_helper"
  gem.license = "Apache-2.0"
  gem.summary = %Q{Standard tasks and configuration for module spec tests}
  gem.description = %Q{Contains rake tasks and a standard spec_helper for running spec tests on puppet modules}
  gem.email = ["modules-dept@puppetlabs.com"]
  gem.authors = ["Puppet Labs"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb'].exclude('spec/fixtures/**/*_spec.rb')
end

namespace :git do
  desc "Create a new tag that uses #{PuppetlabsSpecHelper::Version::STRING} as the tag"
  task :tag do
    `git tag -m '#{PuppetlabsSpecHelper::Version::STRING}'`
  end
  desc "Tag and push to master"
  task :pl_release do
    Rake::Task["git:tag"].invoke
    `git push origin master --tags`
  end
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
