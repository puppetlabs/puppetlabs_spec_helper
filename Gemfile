# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

def location_for(place_or_version, fake_version = nil)
  git_url_regex = %r{\A(?<url>(?:https?|git)[:@][^#]*)(?:#(?<branch>.*))?}
  file_url_regex = %r{\Afile://(?<path>.*)}

  if place_or_version && (git_url = place_or_version.match(git_url_regex))
    [fake_version, { git: git_url[:url], branch: git_url[:branch], require: false }].compact
  elsif place_or_version && (file_url = place_or_version.match(file_url_regex))
    ['>= 0', { path: File.expand_path(file_url[:path]), require: false }]
  else
    [place_or_version, { require: false }]
  end
end

# Specify the global dependencies in puppetlabs_spec_helper.gemspec
# Note that only ruby 1.9 compatible dependencies may go there, everything else needs to be documented and pulled in manually, and optionally by everyone who wants to use the extended features.
gemspec

def infer_puppet_version
  # Infer the Puppet Gem version based on the Ruby Version
  ruby_ver = Gem::Version.new(RUBY_VERSION.dup)
  return '~> 7.0' if ruby_ver >= Gem::Version.new('2.7.0')
  return '~> 6.0' if ruby_ver >= Gem::Version.new('2.5.0')
  '~> 5.0'
end

group :development do
  gem 'codecov'
  gem 'github_changelog_generator' if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.2.0')
  gem 'puppet', *location_for(ENV['PUPPET_GEM_VERSION'] || ENV['PUPPET_VERSION'] || infer_puppet_version)
  gem 'simplecov', '~> 0'
  gem 'simplecov-console'
  if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.4')
    gem 'rubocop', '0.57.2'
    gem 'rubocop-rspec'
  end
end

# vim:filetype=ruby
