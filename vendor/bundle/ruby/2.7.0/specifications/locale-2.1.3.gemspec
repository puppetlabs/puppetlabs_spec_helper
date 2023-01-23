# -*- encoding: utf-8 -*-
# stub: locale 2.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "locale".freeze
  s.version = "2.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kouhei Sutou".freeze, "Masao Mutoh".freeze]
  s.date = "2020-02-12"
  s.description = "Ruby-Locale is the pure ruby library which provides basic APIs for localization.\n".freeze
  s.email = ["kou@clear-code.com".freeze, "mutomasa at gmail.com".freeze]
  s.homepage = "https://github.com/ruby-gettext/locale".freeze
  s.licenses = ["Ruby".freeze, "LGPLv3+".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Ruby-Locale is the pure ruby library which provides basic APIs for localization.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<yard>.freeze, [">= 0"])
    s.add_development_dependency(%q<redcarpet>.freeze, [">= 0"])
    s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
    s.add_development_dependency(%q<test-unit-notify>.freeze, [">= 0"])
    s.add_development_dependency(%q<test-unit-rr>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
    s.add_dependency(%q<redcarpet>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit-notify>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit-rr>.freeze, [">= 0"])
  end
end
