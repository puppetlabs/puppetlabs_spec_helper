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

require 'puppetlabs_spec_helper/puppet_spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
require 'puppetlabs_spec_helper/rake_tasks'

# configure RSpec after including all the code
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec
end
