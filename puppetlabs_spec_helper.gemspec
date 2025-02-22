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

  spec.files = Dir[
    'README.md',
    'LICENSE',
    '.rubocop.yml',
    'lib/**/*',
    'bin/**/*',
    'spec/**/*',
  ]
  spec.executables = Dir['bin/**/*'].map { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = Gem::Requirement.new('>= 2.7')

  spec.add_runtime_dependency 'mocha', '>= 1.0', '< 3'
  spec.add_runtime_dependency 'pathspec', '>= 0.2', '< 3'
  spec.add_runtime_dependency 'puppet-lint', '~> 4.0'
  spec.add_runtime_dependency 'puppet-syntax', '~> 4.1', '>= 4.1.1'
  spec.add_runtime_dependency 'rspec-github', '>= 2.0', '< 4'
  spec.add_runtime_dependency 'rspec-puppet', '~> 5.0'

  spec.add_development_dependency 'voxpupuli-rubocop', '~> 2.8.0'

  spec.requirements << 'puppet, >= 7.0.0'
end
