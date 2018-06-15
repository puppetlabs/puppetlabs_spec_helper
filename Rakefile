# encoding: utf-8
require "bundler/gem_tasks"
require "rspec/core/rake_task"

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

task :default => default_tasks
