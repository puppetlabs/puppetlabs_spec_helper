module PuppetlabsSpecHelper
  FIXTURE_DIR = File.join("spec", "fixtures")
end

require 'puppet'
require 'rspec-puppet'
require 'mocha/api'
require 'puppetlabs_spec_helper/puppetlabs_spec/files'
require 'puppetlabs_spec_helper/puppetlabs_spec/fixtures'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
require 'puppetlabs_spec_helper/puppetlabs_spec/matchers'
require 'puppetlabs_spec_helper/rspec'
