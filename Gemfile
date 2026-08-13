# frozen_string_literal: true

# For puppetcore, set GEM_SOURCE_PUPPETCORE = 'https://rubygems-puppetcore.puppet.com'
gemsource_default = ENV['GEM_SOURCE'] || 'https://rubygems.org'
gemsource_puppetcore = if !ENV['PUPPET_FORGE_TOKEN'].to_s.empty?
                         'https://rubygems-puppetcore.puppet.com'
                       else
                         ENV['GEM_SOURCE_PUPPETCORE'] || gemsource_default
                       end
source gemsource_default

gemspec

def location_for(place_or_version, fake_version = nil, opts = {})
  git_url_regex = %r{\A(?<url>(https?|git)[:@][^#]*)(#(?<branch>.*))?}
  file_url_regex = %r{\Afile:\/\/(?<path>.*)}

  if place_or_version && (git_url = place_or_version.match(git_url_regex))
    [fake_version, { git: git_url[:url], branch: git_url[:branch], require: false }].compact
  elsif place_or_version && (file_url = place_or_version.match(file_url_regex))
    ['>= 0', { path: File.expand_path(file_url[:path]), require: false }]
  else
    [place_or_version, { require: false }.merge(opts)]
  end
end

group :development do
  gem 'puppet', *location_for(ENV.fetch('PUPPET_GEM_VERSION', nil), nil, { source: gemsource_puppetcore })

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
