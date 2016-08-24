# -*- encoding: utf-8 -*-
# stub: puppetlabs_spec_helper 1.2.0 ruby lib
require './lib/puppetlabs_spec_helper/version'

Gem::Specification.new do |s|
  s.name = "puppetlabs_spec_helper"
  s.version = PuppetlabsSpecHelper::Version::STRING

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Puppet Labs"]
  s.date = "2016-08-23"
  s.description = "Contains rake tasks and a standard spec_helper for running spec tests on puppet modules"
  s.email = ["modules-dept@puppetlabs.com"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test)/}) }
  s.homepage = "http://github.com/puppetlabs/puppetlabs_spec_helper"
  s.licenses = ["Apache-2.0"]
  s.rubygems_version = "2.5.1"
  s.summary = "Standard tasks and configuration for module spec tests"

  s.add_runtime_dependency(%q<rake>, [">= 0"])
  s.add_runtime_dependency(%q<rspec-puppet>, [">= 0"])
  s.add_runtime_dependency(%q<rubocop>, [">= 0"])
  s.add_runtime_dependency(%q<rubocop-rspec>, ["~> 1.6"])
  s.add_runtime_dependency(%q<puppet-lint>, [">= 0"])
  s.add_runtime_dependency(%q<puppet-syntax>, [">= 0"])
  s.add_runtime_dependency(%q<mocha>, [">= 0"])
  s.add_runtime_dependency(%q<rack>, ["~> 1"])
  s.add_development_dependency(%q<rspec>, ["~> 3"])
  s.add_development_dependency(%q<yard>, [">= 0"])
  s.add_development_dependency(%q<pry>, [">= 0"])
  s.add_development_dependency(%q<puppet>, ["~> 3.8.3"])

end
