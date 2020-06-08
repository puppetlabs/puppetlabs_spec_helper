source 'https://rubygems.org'

# Specify the global dependencies in puppetlabs_spec_helper.gemspec
# Note that only ruby 1.9 compatible dependencies may go there, everything else needs to be documented and pulled in manually, and optionally by everyone who wants to use the extended features.
gemspec

def infer_puppet_version
  # Infer the Puppet Gem version based on the Ruby Version
  ruby_ver = Gem::Version.new(RUBY_VERSION.dup)
  return '~> 6.0' if ruby_ver >= Gem::Version.new('2.5.0')
  return '~> 5.0' if ruby_ver >= Gem::Version.new('2.4.0')
  '~> 4.0'
end

group :development do
  gem 'codecov'
  gem 'github_changelog_generator' if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.2.0')
  gem 'puppet', ENV['PUPPET_GEM_VERSION'] || ENV['PUPPET_VERSION'] || infer_puppet_version
  gem 'simplecov', '~> 0'
  gem 'simplecov-console'
  if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
    gem 'rubocop', '0.85.1'
    gem 'rubocop-rspec', '~> 1'
  end
end

# json_pure 2.0.2 added a requirement on ruby >= 2. We pin to json_pure 2.0.1
# if using ruby 1.x
gem 'json_pure', '<=2.0.1' if RUBY_VERSION =~ %r{^1\.}
gem 'rack', '~> 1'

# vim:filetype=ruby
