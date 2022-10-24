# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = "spec/acceptance/**/*.rb"
end

RSpec::Core::RakeTask.new(:acceptance) do |t|
  t.pattern = "spec/acceptance/**/*.rb"
end

require 'yard'
YARD::Rake::YardocTask.new
