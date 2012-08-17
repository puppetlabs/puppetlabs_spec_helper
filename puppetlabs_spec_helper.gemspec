# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "puppetlabs_spec_helper"
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Puppet Labs"]
  s.date = "2012-08-15"
  s.description = "Contains rake tasks and a standard spec_helper for running spec tests on puppet modules"
  s.email = ["puppet-dev@puppetlabs.com"]
  s.homepage = "http://github.com/puppetlabs/puppetlabs_spec_helper"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Standard tasks and configuration for module spec tests"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<mocha>, ["~> 0.10.5"])
      s.add_runtime_dependency(%q<rspec>, ["~> 2.10.0"])
      s.add_runtime_dependency(%q<rspec-core>, ["~> 2.10.0"])
      s.add_runtime_dependency(%q<rspec-expectations>, ["~> 2.10.0"])
      s.add_runtime_dependency(%q<rspec-puppet>, [">= 0.1.1"])
      s.add_runtime_dependency(%q<puppet>, [">= 2.6.0"])
      s.add_runtime_dependency(%q<puppet-lint>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<mocha>, ["~> 0.10.5"])
      s.add_dependency(%q<rspec>, ["~> 2.10.0"])
      s.add_dependency(%q<rspec-core>, ["~> 2.10.0"])
      s.add_dependency(%q<rspec-expectations>, ["~> 2.10.0"])
      s.add_dependency(%q<rspec-puppet>, [">= 0.1.1"])
      s.add_dependency(%q<puppet>, [">= 2.6.0"])
      s.add_dependency(%q<puppet-lint>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<mocha>, ["~> 0.10.5"])
    s.add_dependency(%q<rspec>, ["~> 2.10.0"])
    s.add_dependency(%q<rspec-core>, ["~> 2.10.0"])
    s.add_dependency(%q<rspec-expectations>, ["~> 2.10.0"])
    s.add_dependency(%q<rspec-puppet>, [">= 0.1.1"])
    s.add_dependency(%q<puppet>, [">= 2.6.0"])
    s.add_dependency(%q<puppet-lint>, [">= 0"])
  end
end
