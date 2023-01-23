# -*- encoding: utf-8 -*-
# stub: pathspec 1.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "pathspec".freeze
  s.version = "1.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brandon High".freeze]
  s.date = "2022-01-30"
  s.description = "Use to match path patterns such as gitignore".freeze
  s.email = "highb@users.noreply.github.com".freeze
  s.executables = ["pathspec-rb".freeze]
  s.files = ["bin/pathspec-rb".freeze]
  s.homepage = "https://github.com/highb/pathspec-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.9".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "PathSpec: for matching path patterns".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, ["~> 2.2"])
    s.add_development_dependency(%q<fakefs>.freeze, ["~> 1.3"])
    s.add_development_dependency(%q<kramdown>.freeze, ["~> 2.3"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.10"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.7"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.21"])
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 2.2"])
    s.add_dependency(%q<fakefs>.freeze, ["~> 1.3"])
    s.add_dependency(%q<kramdown>.freeze, ["~> 2.3"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.10"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 1.7"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.21"])
  end
end
