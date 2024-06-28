# frozen_string_literal: true

require 'rspec-puppet'
require 'puppetlabs_spec_helper/puppet_spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

def param_value(subject, type, title, param)
  subject.resource(type, title).send(:parameters)[param.to_sym]
end

def verify_contents(subject, title, expected_lines)
  content = subject.resource('file', title).send(:parameters)[:content]
  expect(content.split("\n") & expected_lines).to match_array expected_lines.uniq
end

spec_path = File.expand_path(File.join(Dir.pwd, 'spec'))
fixture_path = File.join(spec_path, 'fixtures')

env_module_path = ENV.fetch('MODULEPATH', nil)
module_path = File.join(fixture_path, 'modules')

module_path = [module_path, env_module_path].join(File::PATH_SEPARATOR) if env_module_path

if ENV['SIMPLECOV'] == 'yes'
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

  begin
    require 'codecov'
    SimpleCov.formatters << SimpleCov::Formatter::Codecov
  rescue LoadError
    # continue without codecov, we could warn here but we want to avoid its use if possible
  end

  SimpleCov.start do
    track_files 'lib/**/*.rb'
    add_filter '/spec'

    # do not track vendored files
    add_filter '/vendor'
    add_filter '/.vendor'

    # do not track gitignored files
    # this adds about 4 seconds to the coverage check
    # this could definitely be optimized
    add_filter do |f|
      # system returns true if exit status is 0, which with git-check-ignore means file is ignored
      system("git check-ignore --quiet #{f.filename}")
    end
  end
end

# Add all spec lib dirs to LOAD_PATH
components = module_path.split(File::PATH_SEPARATOR).map do |dir|
  next unless Dir.exist? dir

  Dir.entries(dir).grep_v(/^\./).map { |f| File.join(dir, f, 'spec', 'lib') }
end
components.compact.flatten.each do |d|
  $LOAD_PATH << d if FileTest.directory?(d) && !$LOAD_PATH.include?(d)
end

RSpec.configure do |c|
  c.formatter = 'RSpec::Github::Formatter' if ENV['GITHUB_ACTIONS'] == 'true'

  c.environmentpath = spec_path
  c.module_path = module_path

  # https://github.com/puppetlabs/rspec-puppet#strict_variables
  c.strict_variables = ENV['STRICT_VARIABLES'] != 'no'
  # https://github.com/puppetlabs/rspec-puppet#ordering
  c.ordering = ENV['ORDERING'] if ENV['ORDERING']

  c.before :each do
    if c.mock_framework.framework_name == :rspec
      allow(Puppet.features).to receive(:root?).and_return(true)
    else
      Puppet.features.stubs(:root?).returns(true)
    end
  end
end
