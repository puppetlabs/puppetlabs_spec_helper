# -*- encoding: utf-8 -*-
# stub: puppet-resource_api 1.8.14 ruby lib

Gem::Specification.new do |s|
  s.name = "puppet-resource_api".freeze
  s.version = "1.8.14"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Schmitt".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-06-09"
  s.email = ["david.schmitt@puppet.com".freeze]
  s.homepage = "https://github.com/puppetlabs/puppet-resource_api".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "This library provides a simple way to write new native resources for puppet.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<hocon>.freeze, [">= 1.0"])
  else
    s.add_dependency(%q<hocon>.freeze, [">= 1.0"])
  end
end
