# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "semantic_puppet/gem_version"

spec = Gem::Specification.new do |s|
  # Metadata
  s.name        = "semantic_puppet"
  s.version     = SemanticPuppet::VERSION
  s.authors     = ["Puppet Labs"]
  s.email       = ["info@puppetlabs.com"]
  s.homepage    = "https://github.com/puppetlabs/semantic_puppet"
  s.summary     = "Useful tools for working with Semantic Versions."
  s.description = %q{Tools used by Puppet to parse, validate, and compare Semantic Versions and Version Ranges and to query and resolve module dependencies.}
  s.licenses    = ['Apache-2.0']

  # Manifest
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*_spec.rb`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Dependencies
  s.required_ruby_version = '>= 1.9.3'

  s.add_development_dependency "json", "~> 1.8.3" if RUBY_VERSION < '2.0'
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"

  unless RUBY_PLATFORM =~ /java/
    s.add_development_dependency "simplecov"
    s.add_development_dependency "cane"
    s.add_development_dependency "yard"
    s.add_development_dependency "redcarpet"
  end
end
