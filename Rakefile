# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = 'spec/acceptance/**/*.rb'
end

namespace :spec do
  desc 'Run RSpec code examples with coverage collection'
  task :coverage do
      ENV['COVERAGE'] = 'yes'
      Rake::Task['spec'].execute
  end
end

RSpec::Core::RakeTask.new(:acceptance) do |t|
  t.pattern = 'spec/acceptance/**/*.rb'
end

require 'yard'
YARD::Rake::YardocTask.new

begin
  require 'voxpupuli/rubocop/rake'
rescue LoadError
  # the voxpupuli-rubocop gem is optional
end
