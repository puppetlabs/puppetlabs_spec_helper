# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puppetlabs_spec_helper/version'

Gem::Specification.new do |spec|
  spec.name          = "puppetlabs_spec_helper"
  spec.version       = PuppetlabsSpecHelper::VERSION
  spec.authors       = ["Puppet, Inc.", "Community Contributors"]
  spec.email         = ["modules-team@puppet.com"]

  spec.summary       = %q{Standard tasks and configuration for module spec tests.}
  spec.description   = %q{Contains rake tasks and a standard spec_helper for running spec tests on puppet modules.}
  spec.homepage      = "http://github.com/puppetlabs/puppetlabs_spec_helper"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "mocha", "~> 1.0"
  spec.add_runtime_dependency "puppet-lint", "~> 2.0"
  spec.add_runtime_dependency "puppet-syntax", "~> 2.0"
  spec.add_runtime_dependency "rspec-puppet", "~> 2.0"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "puppet", "~> 3"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "yard"
end
