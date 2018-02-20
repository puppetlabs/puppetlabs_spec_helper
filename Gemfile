source 'https://rubygems.org'

# Specify the global dependencies in puppetlabs_spec_helper.gemspec
gemspec

group :development do
  gem "puppet", ENV['PUPPET_GEM_VERSION'] || ENV['PUPPET_VERSION'] || '~> 5.0'
  gem 'rubocop', '= 0.49.1'
  gem 'rubocop-rspec', '= 1.15.1'
end

gem 'rack', '~> 1'

# vim:filetype=ruby
