require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/.vendor/'
  add_filter '/vendor/'
  add_filter '/gems/'
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
