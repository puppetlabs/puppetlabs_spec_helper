# -*- encoding: utf-8 -*-
# stub: pry-byebug 3.10.1 ruby lib

Gem::Specification.new do |s|
  s.name = "pry-byebug".freeze
  s.version = "3.10.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Rodr\u00EDguez".freeze, "Gopal Patel".freeze]
  s.date = "2022-08-16"
  s.description = "Combine 'pry' with 'byebug'. Adds 'step', 'next', 'finish',\n    'continue' and 'break' commands to control execution.".freeze
  s.email = "deivid.rodriguez@gmail.com".freeze
  s.extra_rdoc_files = ["CHANGELOG.md".freeze, "README.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "README.md".freeze]
  s.homepage = "https://github.com/deivid-rodriguez/pry-byebug".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Fast debugging with Pry.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<byebug>.freeze, ["~> 11.0"])
    s.add_runtime_dependency(%q<pry>.freeze, [">= 0.13", "< 0.15"])
  else
    s.add_dependency(%q<byebug>.freeze, ["~> 11.0"])
    s.add_dependency(%q<pry>.freeze, [">= 0.13", "< 0.15"])
  end
end
