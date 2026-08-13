# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

# Temporary: resolve puppet-syntax from the puppetlabs-maintained fork (5.1.x
# line, puppet >= 7, < 10) for Puppet 9 support, until 5.1.0 is published to
# the gem repo. Remove once published. See MODULES-11926.
gem 'puppet-syntax', git: 'https://github.com/puppetlabs/puppet-syntax', tag: '5.1.0'

def location_for(place_or_version, fake_version = nil)
  git_url_regex = %r{\A(?<url>(https?|git)[:@][^#]*)(#(?<branch>.*))?}
  file_url_regex = %r{\Afile:\/\/(?<path>.*)}

  if place_or_version && (git_url = place_or_version.match(git_url_regex))
    [fake_version, { git: git_url[:url], branch: git_url[:branch], require: false }].compact
  elsif place_or_version && (file_url = place_or_version.match(file_url_regex))
    ['>= 0', { path: File.expand_path(file_url[:path]), require: false }]
  else
    [place_or_version, { require: false }]
  end
end

group :development do
  gem 'puppet', *location_for(ENV['PUPPET_GEM_VERSION'])

  gem 'simplecov'
  gem 'simplecov-console'

  gem 'pry', require: false
  gem 'pry-byebug', require: false
  gem 'pry-stack_explorer', require: false

  gem 'rake'
  gem 'rspec', '~> 3.1'
  gem 'rspec-its', '>= 1.0', '< 3'

  gem 'fakefs'
  gem 'yard'
end
