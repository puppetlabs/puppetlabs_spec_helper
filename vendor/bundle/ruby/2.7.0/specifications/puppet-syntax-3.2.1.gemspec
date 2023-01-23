# -*- encoding: utf-8 -*-
# stub: puppet-syntax 3.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "puppet-syntax".freeze
  s.version = "3.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Vox Pupuli".freeze]
  s.date = "2022-05-16"
  s.description = "Syntax checks for Puppet manifests and templates".freeze
  s.email = ["voxpupuli@groups.io".freeze]
  s.homepage = "https://github.com/voxpupuli/puppet-syntax".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Syntax checks for Puppet manifests, templates, and Hiera YAML".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rake>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<puppet>.freeze, [">= 5"])
    s.add_development_dependency(%q<pry>.freeze, [">= 0"])
    s.add_development_dependency(%q<rb-readline>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<puppet>.freeze, [">= 5"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
    s.add_dependency(%q<rb-readline>.freeze, [">= 0"])
  end
end
