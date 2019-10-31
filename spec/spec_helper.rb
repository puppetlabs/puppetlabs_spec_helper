if ENV['COVERAGE'] == 'yes'
  require 'simplecov'
  require 'simplecov-console'
  require 'codecov'

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console,
    SimpleCov::Formatter::Codecov,
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
require 'puppetlabs_spec_helper/util'

extend PuppetlabsSpecHelper::Util

RSpec.shared_context 'rake task', type: :task do
  subject(:task) { Rake::Task[task_name] }

  include FakeFS::SpecHelpers

  let(:task_name) { self.class.top_level_description.sub(%r{\Arake }, '') }
end

# configure RSpec after including all the code
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec

  config.include_context 'rake task', type: :task
end

RSpec::Matchers.define :output_json do |expected|
  supports_block_expectations

  match do |block|
    raw_output = (@method || method(:capture_null)).call(block)
    @actual = JSON.parse(raw_output)
    values_match?(expected, @actual)
  end

  diffable

  def capture_null(_block)
    raise 'You must chain `to_stdout` or `to_stderr` off of the `output_json(...)` matcher.'
  end

  def capture_stdout(block)
    captured = StringIO.new
    original = $stdout
    $stdout = captured

    block.call

    captured.string
  ensure
    $stdout = original
  end

  def capture_stderr(block)
    captured = StringIO.new
    original = $stderr
    $stderr = captured

    block.call

    captured.string
  ensure
    $stderr = original
  end

  chain :to_stdout do
    @method = method(:capture_stdout)
  end

  chain :to_stderr do
    @method = method(:capture_stderr)
  end

  description do
    "contain a JSON object including #{expected.to_json}"
  end

  failure_message do |actual|
    "expected that #{actual.to_json} would contain #{expected.to_json}"
  end
end
