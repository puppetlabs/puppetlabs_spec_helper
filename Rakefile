require 'rake'
require 'rake/packagetask'
require 'rubygems/package_task'

task :default do
    sh %{rake -T}
end

require 'fileutils'

def version
# This ugly bit removes the gSHA1 portion of the describe as that causes failing tests
  if File.exists?('.git')
    %x{git describe}.chomp.gsub('-', '.').split('.')[0..3].join('.').gsub('v', '')
  else
    %x{pwd}.strip!.split('.')[-1]
  end
end

spec = Gem::Specification.new do |s|
  s.name        = "puppetlabs_spec_helper"
  s.version     = version
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Puppet Labs"]
  s.email       = ["puppet-dev@puppetlabs.com"]
  s.homepage    = "http://github.com/puppetlabs/puppetlabs_spec_helper"
  s.summary     = "Standard tasks and configuration for module spec tests"
  s.description = "Contains rake tasks and a standard spec_helper for running spec tests on puppet modules"
  s.licenses    = 'Apache-2.0'

  s.add_dependency("rake")
  s.add_dependency("rspec", ">= 2.9.0")
  s.add_dependency("mocha", ">= 0.10.5")
  s.add_dependency("rspec-puppet", ">= 0.1.1")

  s.files        = Dir.glob("lib/**/*") + %w(LICENSE) + %w(CHANGELOG)
  s.require_path = 'lib'
end

namespace :package do
  desc "Create the gem"
  task :gem do
      Dir.mkdir("pkg") rescue nil
      if Gem::Version.new(`gem -v`) >= Gem::Version.new("2.0.0.a")
        Gem::Package.build(spec)
      else
        Gem::Builder.new(spec).build
      end
      FileUtils.move("puppetlabs_spec_helper-#{version}.gem", "pkg")
  end
end

desc "Cleanup pkg directory"
task :clean do
  FileUtils.rm_rf("pkg")
end
