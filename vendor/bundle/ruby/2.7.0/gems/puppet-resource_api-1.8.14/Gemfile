source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in puppet-resource_api.gemspec
gemspec

group :tests do
  gem 'CFPropertyList'
  gem 'rspec', '~> 3.0'
  gem 'simplecov-console'

  # the test gems required for module testing
  gem 'puppetlabs_spec_helper', '~> 3.0'
  gem 'rspec-puppet'

  # since the Resource API runs inside the puppetserver, test against the JRuby versions we ship
  # these require special dependencies to have everything load properly

  # `codecov` 0.1.17 introduced usage of %i[] which is not recognised by JRuby 1.7
  if RUBY_PLATFORM == 'java' && Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3.0')
    gem 'codecov', '= 0.1.16'
  else
    gem 'codecov'
  end

  # `rake` dropped support for older versions of ruby a while back
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.1.0')
    gem 'rake', '11.3.0'
  elsif Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.2.0')
    gem 'rake', '12.3.3'
  else
    gem 'rake', '~> 13.0'
  end

  # rubocop is special, as usual
  if RUBY_PLATFORM == 'java'
    # load a rubocop version that works on java for the Rakefile
    gem 'parser', '2.3.3.1'
    gem 'rubocop', '0.41.2'
  elsif Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.2.0')
    # rubocop 0.58 throws when testing against ruby 2.1, so pin to the latest version that works
    gem 'rubocop', '0.57.2'
    gem 'rubocop-rspec'
  else
    # 2.1-compatible analysis was dropped after version 0.58
    # This needs to be removed once we drop puppet4 support.
    gem 'rubocop', '~> 0.57.0'
    gem 'rubocop-rspec'
  end

  # JRuby 1.7 does not like json 2.3.0, jruby 9.1.9.0 has RUBY_VERSION == '2.3.3'
  gem 'json', '2.2.0' if RUBY_PLATFORM == 'java' && Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3.0')
  # the last version of parallel to support ruby 2.1
  gem 'parallel', '1.13.0' if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.2.0')

  # license_finder does not install on windows using older versions of rubygems.
  # ruby 2.4 is confirmed working on appveyor and we only need to run it on the newest gemset anyways
  gem 'license_finder' if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.4.0')
end

group :development do
  gem 'github_changelog_generator', '~> 1.15' if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.3.0')
  gem 'pry-byebug'
end

# Find a location or specific version for a gem. place_or_version can be a
# version, which is most often used. It can also be git, which is specified as
# `git://somewhere.git#branch`. You can also use a file source location, which
# is specified as `file://some/location/on/disk`.
def location_for(place_or_version, fake_version = nil)
  if place_or_version =~ /^((?:git|https)[:@][^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place_or_version =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place_or_version, { :require => false }]
  end
end

gem 'puppet', *location_for(ENV['PUPPET_GEM_VERSION'])
