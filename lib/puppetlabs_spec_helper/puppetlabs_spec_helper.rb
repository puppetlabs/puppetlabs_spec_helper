# Define the main module namespace for use by the helper modules
module PuppetlabsSpecHelper
  # FIXTURE_DIR represents the standard locations of all fixture data. Normally
  # this represents <project>/spec/fixtures. This will be used by the fixtures
  # library to find relative fixture data.
  FIXTURE_DIR = File.join("spec", "fixtures") unless defined?(FIXTURE_DIR)
end

# Require all necessary helper libraries so they can be used later
require 'puppetlabs_spec_helper/puppetlabs_spec/files'
require 'puppetlabs_spec_helper/puppetlabs_spec/fixtures'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
require 'puppetlabs_spec_helper/puppetlabs_spec/matchers'

RSpec.configure do |config|
  # Include PuppetlabsSpecHelper helpers so they can be called at convenience
  config.extend PuppetlabsSpecHelper::Files
  config.extend PuppetlabsSpecHelper::Fixtures
  config.include PuppetlabsSpecHelper::Fixtures

  # This will cleanup any files that were created with tmpdir or tmpfile
  config.after do
    PuppetlabsSpecHelper::Files.cleanup
  end
end
