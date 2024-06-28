# frozen_string_literal: true

if ENV['COVERAGE'] == 'yes'
  begin
    require 'simplecov'
    require 'simplecov-console'
  rescue LoadError
    raise 'Add the simplecov and simplecov-console gems to Gemfile to enable this task'
  end

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console,
  ]

  SimpleCov.start do
    track_files 'lib/**/*.rb'

    add_filter 'lib/puppetlabs_spec_helper/version.rb'

    add_filter '/spec'

    # do not track vendored files
    add_filter '/vendor'
    add_filter '/.vendor'
  end
end

require 'fakefs/spec_helpers'

FakeFS::Pathname.class_eval do
  def symlink?
    File.symlink?(@path)
  end
end

require 'puppetlabs_spec_helper/puppet_spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
require 'puppetlabs_spec_helper/rake_tasks'

RSpec.shared_context 'with a rake task', type: :task do
  subject(:task) { Rake::Task[task_name] }

  include FakeFS::SpecHelpers

  let(:task_name) { self.class.top_level_description.delete_prefix('rake ') }
end

# configure RSpec after including all the code
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include_context 'with a rake task', type: :task
end
