# encoding: utf-8

require 'rubygems'
require 'bundler'
require "bundler/gem_tasks"
require "rake/testtask"
require './lib/puppetlabs_spec_helper/version'

begin
  Bundler.setup(:default, :development, :test)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb'].exclude('spec/fixtures/**/*_spec.rb')
end

# this is required because the gem has historically used tags without the `v` ie.
# v1.3.1 vs 1.3.1.  By default bundler now enforces v1.3.1 as the default standard.
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

desc "Show the generated gemspec"
task :show_gemspec do
  Rake::Task['build'].invoke
  puts `gem specification pkg/puppetlabs_spec_helper-#{PuppetlabsSpecHelper::Version::STRING}.gem --ruby`
end

task :default => :spec

require 'rubocop/rake_task'
RuboCop::RakeTask.new

require 'yard'
YARD::Rake::YardocTask.new
