# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puppetlabs_spec_helper/version'

Gem::Specification.new do |spec|
  spec.name          = 'puppetlabs_spec_helper'
  spec.version       = PuppetlabsSpecHelper::VERSION
  spec.authors       = ['Puppet, Inc.', 'Community Contributors']
  spec.email         = ['modules-team@puppet.com']

  spec.summary       = 'Standard tasks and configuration for module spec tests.'
  spec.description   = 'Contains rake tasks and a standard spec_helper for running spec tests on puppet modules.'
  spec.homepage      = 'http://github.com/puppetlabs/puppetlabs_spec_helper'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = Gem::Requirement.new('>= 2.4')

  spec.add_runtime_dependency 'mocha', '~> 1.0'
  spec.add_runtime_dependency 'pathspec', '>= 0.2.1', '< 1.1.0'
  spec.add_runtime_dependency 'puppet-lint', '>= 2', '< 4'
  spec.add_runtime_dependency 'puppet-syntax', ['>= 2.0', '< 4']
  spec.add_runtime_dependency 'rspec-puppet', '~> 2.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'fakefs', ['>= 0.13.3', '< 2']
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'puppet'
  spec.add_development_dependency 'rake', ['>= 10.0', '< 14']
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'yard'
end
