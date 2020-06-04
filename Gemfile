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
    gem 'rubocop', '= 0.49'
    gem 'rubocop-rspec', '~> 1'
  end
end

# pin some gems for older ruby versions
gem 'fakefs', '<= 0.13.3' if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.4.0')
gem 'json_pure', '<=2.0.1' if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.0.0')
gem 'puppet-syntax', '<= 3' if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.4.0')
gem 'rack', '~> 1' if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.2.0')

# vim:filetype=ruby
