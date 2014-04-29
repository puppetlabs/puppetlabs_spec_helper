$: << File.expand_path('../lib', __FILE__)

require 'puppetlabs_spec_helper/version'

Gem::Specification.new do |s|
  s.name        = "puppetlabs_spec_helper"
  s.version     = PuppetlabsSpecHelper::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Puppet Labs"]
  s.email       = ["puppet-dev@puppetlabs.com"]
  s.homepage    = "http://github.com/puppetlabs/puppetlabs_spec_helper"
  s.summary     = "Standard tasks and configuration for module spec tests"
  s.description = "Contains rake tasks and a standard spec_helper for running spec tests on puppet modules"
  s.licenses    = 'Apache-2.0'

  s.add_dependency "rake"
  s.add_dependency "rspec", "~> 2.9.0"
  s.add_dependency "rspec-puppet", "~> 1.0.1"
  s.add_dependency "puppet-lint", "~> 0.3.2"
  s.add_dependency "puppet", "~> 3.5.1"
  s.add_dependency "mocha", "~> 0.14.0"

  s.files        = Dir.glob("lib/**/*") + %w(LICENSE CHANGELOG)
  s.require_path = 'lib'
end
