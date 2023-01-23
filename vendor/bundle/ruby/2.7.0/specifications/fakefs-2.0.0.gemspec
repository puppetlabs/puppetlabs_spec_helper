# -*- encoding: utf-8 -*-
# stub: fakefs 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "fakefs".freeze
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Wanstrath".freeze, "Scott Taylor".freeze, "Jeff Hodges".freeze, "Pat Nakajima".freeze, "Brian Donovan".freeze]
  s.date = "2023-01-04"
  s.description = "A fake filesystem. Use it in your tests.".freeze
  s.email = ["chris@ozmm.org".freeze]
  s.homepage = "https://github.com/fakefs/fakefs".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "A fake filesystem. Use it in your tests.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bump>.freeze, ["~> 0.5.3"])
    s.add_development_dependency(%q<maxitest>.freeze, ["~> 3.6"])
    s.add_development_dependency(%q<rake>.freeze, [">= 10.3"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.1"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.82.0"])
  else
    s.add_dependency(%q<bump>.freeze, ["~> 0.5.3"])
    s.add_dependency(%q<maxitest>.freeze, ["~> 3.6"])
    s.add_dependency(%q<rake>.freeze, [">= 10.3"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.1"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.82.0"])
  end
end
